package core;

import core.Input;
import core.Types;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.Scaler;
import kha.Scheduler;
import kha.ScreenCanvas;
import kha.Shaders;
import kha.System;
import kha.graphics4.FragmentShader;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.input.Keyboard;
import kha.input.Mouse;

enum ScaleMode {
    PixelPerfect;
    None;
    Full; // default kha behavior
}

/**
    The main class.  Initializing this will initialize Kha, inputs, the current
    time, the update and render loops, etc.
**/
class Game {
    // Time since the game has been launched.  Updated by Kha's scheduler.
    public var currentTime:Float = 0.0;

    // The current scene being updated and rendered.
    var currentScene:Scene;

    // The backbuffer being drawn on to be scaled.  Not used in scaleMode `Fit`.
    var backbuffer:Image;

    // Mode in which to scale the game.
    var scaleMode:ScaleMode;

    // Mouse input controller.
    public var mouse:MouseInput = new MouseInput();

    // Keyboard input controller.
    public var keys:KeysInput = new KeysInput();

    // Physics object.  Not really udpated now, may best be suited to turn
    // mthods into static.
    public var physics:Physics = new Physics();

    // Main and only camera.
    public var camera:Camera;

    // Size of the game, meant to _not_ change for the time being.
    public var size:IntVec2;

    // Size of the buffer.
    public var bufferSize:IntVec2;

    // The pipeline used to render the full screen.
    static var fullScreenPipeline: PipelineState;

    public function new (
        size:IntVec2,
        initalScene:Scene,
        scaleMode:ScaleMode = None,
        ?name:String,
        ?initialSize:IntVec2
    ) {
        this.scaleMode = scaleMode;
        this.size = size;

        System.start({ title: name, width: size.x, height: size.y }, (_window) -> {
            bufferSize = initialSize != null ? initialSize : size;
            backbuffer = Image.createRenderTarget(bufferSize.x, bufferSize.y);
            backbuffer.g2.imageScaleQuality = Low;

            camera = new Camera(0, 0, bufferSize.x, bufferSize.y);

            // just the movement is PP or None, not `Full`
            if (scaleMode == Full) {
                Mouse.get().notify(mouse.pressMouse, mouse.releaseMouse, mouse.mouseMove);
            } else {
                // need to handle screen position and screen scale
                Mouse.get().notify(mouse.pressMouse, mouse.releaseMouse, onMouseMove);
            }

            Mouse.get().hideSystemCursor();

            if (Keyboard.get() != null) {
                Keyboard.get().notify(keys.pressButton, keys.releaseButton);
            }

            Assets.loadImage('made_with_kha', (_:Image) -> {
                switchScene(new PreloadScene());
                Scheduler.addTimeTask(() -> { update(); }, 0, 1 / 60);

                if (scaleMode == Full) {
                    System.notifyOnFrames((frames) -> { render(frames[0]); });
                } else {
                    System.notifyOnFrames((frames) -> { renderScaled(frames[0]); });
                }

                Assets.loadEverything(() -> {
                    switchScene(initalScene);
                });
            });

            setFullscreenShader(Shaders.painter_image_frag);
        });
    }

    function update () {
        final now = Scheduler.time();
        final delta = now - currentTime;

        // update mouse for camera position
        mouse.setMousePos(
            Std.int(camera.scroll.x + mouse.screenPos.x / camera.scale.x),
            Std.int(camera.scroll.y + mouse.screenPos.y / camera.scale.y)
        );

        currentScene.updateProgress(Assets.progress);
        currentScene.update(delta);
        // physics.update(delta); // not used
        camera.update(delta);

        // after the sprites and scene to clear `justPressed`
        keys.update(delta);
        mouse.update(delta);

        currentTime = now;
    }

    function render (framebuffer:Framebuffer) {
        framebuffer.g2.begin(true, camera.bgColor);
        currentScene.render(framebuffer.g2, camera);
#if debug_physics
        currentScene.renderDebug(framebuffer.g2, camera);
#end
        framebuffer.g2.pipeline = fullScreenPipeline;
        framebuffer.g2.end();
    }

    function renderScaled (framebuffer:Framebuffer) {
        backbuffer.g2.begin(true, camera.bgColor);
        currentScene.render(backbuffer.g2, camera);
#if debug_physics
        currentScene.renderDebug(backbuffer.g2, camera);
#end
        backbuffer.g2.end();

        framebuffer.g2.begin(true, Color.Black);
        framebuffer.g2.pipeline = fullScreenPipeline;
        if (scaleMode == PixelPerfect) {
            ScalerExp.scalePixelPerfect(backbuffer, framebuffer);
        } else {
            Scaler.scale(backbuffer, framebuffer, RotationNone);
        }
        framebuffer.g2.end();
    }

    function onMouseMove (x:Int, y:Int, moveX:Int, moveY:Int) {
        // NOTE: pass in scaling when there is zoom?
        if (scaleMode == PixelPerfect) {
            mouse.mouseMove(
                ScalerExp.transformPixelPerfectX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformPixelPerfectY(y, backbuffer, ScreenCanvas.the),
                ScalerExp.transformPixelPerfectX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformPixelPerfectY(y, backbuffer, ScreenCanvas.the)
            );
        } else {
            mouse.mouseMove(
                ScalerExp.transformX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformY(y, backbuffer, ScreenCanvas.the),
                ScalerExp.transformX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformY(y, backbuffer, ScreenCanvas.the)
            );
        }
    }

    // Switches the currently updated and rendered scene to a new one. Destroys
    // the previous scene.
    public function switchScene (scene:Scene, ?callback:Void -> Void) {
        if (currentScene != null) {
            scene.destroy();
        }

        camera = new Camera(0, 0, bufferSize.x, bufferSize.y);
        scene.game = this;
        scene.create();
        currentScene = scene;

        if (callback != null) {
            callback();
        }
    }

    // Set the shader to be used to render the full screen.
	public function setFullscreenShader (fragShader:FragmentShader) {
		fullScreenPipeline = new PipelineState();
		final structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float32_3X);
		structure.add("vertexUV", VertexData.Float32_2X);
		structure.add("vertexColor", VertexData.UInt8_4X_Normalized);
		fullScreenPipeline.inputLayout = [structure];
		fullScreenPipeline.vertexShader = Shaders.painter_image_vert;
		fullScreenPipeline.fragmentShader = fragShader;
		fullScreenPipeline.compile();
	}
}
