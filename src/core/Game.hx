package core;

import core.ImageShader;
import core.Input;
import core.Types;
import haxe.Exception;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.Scaler;
import kha.Scheduler;
import kha.ScreenCanvas;
import kha.System;
import kha.graphics4.PipelineState;
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
    static inline final UPDATE_TIME:Float = 1 / 60;

    // Time since the game has been launched.  Updated by Kha's scheduler.
    public var currentTime:Float = 0.0;

    // The current list of scenes being updated and rendered.
    var scenes:Array<Scene> = [];

    // Scenes to be added to the current list of scenes.
    var newScenes:Array<Scene> = [];

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

    // Size of the game, meant to _not_ change for the time being.
    public var size:IntVec2;

    // Size of the buffer.
    public var bufferSize:IntVec2;

    // The pipeline used to render the backbuffer.
    // var backbufferPipeline: PipelineState;

    // The pipeline used to render the full screen.
    var fullScreenPipeline: PipelineState;

    public function new (
        size:IntVec2,
        initalScene:Scene,
        scaleMode:ScaleMode = None,
        name:String,
        ?initialSize:IntVec2,
        ?exceptionHandler:Exception -> Void,
        ?compressedAudioFilter:Dynamic -> Bool
    ) {
        this.scaleMode = scaleMode;
        this.size = size;

        if (exceptionHandler == null) {
            exceptionHandler = (e:Exception) -> throw e;
        }

        System.start({ title: name, width: size.x, height: size.y }, (_window) -> {
            bufferSize = initialSize != null ? initialSize : size;
            backbuffer = Image.createRenderTarget(bufferSize.x, bufferSize.y);
            backbuffer.g2.imageScaleQuality = Low;

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

                // HACK: run `update()` once to get preload scene from `newScenes` to `scenes`.
                // This kicks off the game.
                try { update(); } catch (e) { exceptionHandler(e); }

                Scheduler.addTimeTask(
                    () -> {
                        try { update(); } catch (e) { exceptionHandler(e); }
                    },
                    0,
                    UPDATE_TIME
                );

                if (scaleMode == Full) {
                    System.notifyOnFrames((frames) -> {
                        try { render(frames[0]); } catch (e) { exceptionHandler(e); }
                    });
                } else {
                    System.notifyOnFrames(
                        (frames) -> {
                            try { renderScaled(frames[0]); } catch (e) { exceptionHandler(e); }
                        }
                    );
                }

                function allAssets (_:Dynamic) return true;

                Assets.loadEverything(() -> {
                    switchScene(initalScene);
                }, null, compressedAudioFilter != null ? compressedAudioFilter : allAssets);
            });

            setFullscreenShader(makeBasePipelineShader());
            // setBackbufferShader(makeBasePipelineShader());
        });
    }

    function update () {
        final now = Scheduler.time();
        final delta = now - currentTime;

        // update mouse for camera position
        final camExists = scenes[0] != null;
        mouse.setMousePos(
            Std.int(
                (camExists ? scenes[0].camera.scroll.x : 0) + mouse.screenPos.x /
                (camExists ? scenes[0].camera.scale.x : 0)
            ),
            Std.int(
                (camExists ? scenes[0].camera.scroll.y : 0) + mouse.screenPos.y /
                (camExists ? scenes[0].camera.scale.y : 0)
            )
        );

        for (s in newScenes) scenes.push(s);
        newScenes = [];
        for (s in scenes) {
            if (!s.isPaused) {
                s.updateProgress(Assets.progress);
                s.update(UPDATE_TIME);
            }
        }
        scenes = scenes.filter((s) -> !s._destroyed);

        // after the scenes to clear `justPressed`
        keys.update(UPDATE_TIME);
        mouse.update(UPDATE_TIME);

        currentTime = now;
    }

    function render (framebuffer:Framebuffer) {
        framebuffer.g2.begin(true);
        framebuffer.g2.pipeline = fullScreenPipeline;
        for (s in scenes) {
            framebuffer.g2.clear(s.camera.bgColor);
            s.render(backbuffer.g2);
        }
#if debug_physics
        for (s in scenes) s.renderDebug(framebuffer.g2);
#end
        framebuffer.g2.end();
    }

    function renderScaled (framebuffer:Framebuffer) {
        backbuffer.g2.begin(true);

        if (scenes[0] != null) {
            backbuffer.g2.clear(scenes[0].camera.bgColor);
        }

        for (s in scenes) {
            s.render(backbuffer.g2);
        }
        #if debug_physics
        for (s in scenes) s.renderDebug(backbuffer.g2);
        #end
        // backbuffer.g2.pipeline = backbufferPipeline;
        backbuffer.g2.end();

        framebuffer.g2.begin(true, 0xff000000);
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

    // Switches the currently updated and rendered scene(s) to a new one. Destroys
    // _all_ of the previous scenes.
    public function switchScene (scene:Scene, ?callback:Void -> Void) {
        for (s in scenes) s.destroy();
        // scenes = [];

        addScene(scene);

        if (callback != null) {
            callback();
        }
    }

    public function removeScene (scene:Scene) {
        scene.destroy();
        scenes.filter((s) -> s != scene);
    }

    public function addScene (scene:Scene) {
        newScenes.push(scene);
        scene.game = this;
        scene.camera = new Camera(0, 0, bufferSize.x, bufferSize.y);
        scene.create();
    }

    // // Set the shader to be used to render the backbuffer.
    // NOTE: commented out because it draws black over sprites behind it
    // public function setBackbufferShader (imageShader:ImageShader) {
    //     backbufferPipeline = imageShader.pipeline;
    // }

    // Set the shader to be used to render the full screen.
    public function setFullscreenShader (imageShader:ImageShader) {
        fullScreenPipeline = imageShader.pipeline;
    }
}
