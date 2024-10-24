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
import kha.input.Gamepad;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.input.Surface;

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

    // gamepad input controller.
    public var gamepads:Gamepads = new Gamepads();

    // Surface (touch) input controller.
    public var surface:SurfaceInput = new SurfaceInput();

    // Physics object.  Not really udpated now, may best be suited to turn
    // mthods into static.
    public var physics:Physics = new Physics();

    // Size of the game.
    public var size:IntVec2;

    // Size of the buffer.
    public var bufferSize:IntVec2;

    // The pipeline used to render the backbuffer.
    var backbufferPipeline: PipelineState;

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
            if (scaleMode != Full) {
                backbuffer = Image.createRenderTarget(bufferSize.x, bufferSize.y);
                backbuffer.g2.imageScaleQuality = Low;
            }

            // just the movement is PP or None, not `Full`
            if (scaleMode == Full) {
                Mouse.get().notify(mouse.pressMouse, mouse.releaseMouse, mouse.mouseMove);
                Surface.get().notify(surface.press, surface.release, surface.move);
            } else {
                // need to handle screen position and screen scale
                Mouse.get().notify(mouse.pressMouse, mouse.releaseMouse, onMouseMove);
                Surface.get().notify(surface.press, surface.release, onSurfaceMove);
            }

            // for WEGO
            // Mouse.get().hideSystemCursor();

            if (Keyboard.get() != null) {
                Keyboard.get().notify(keys.pressButton, keys.releaseButton);
            }

            for (i in 0...8) {
                if (Gamepad.get(i) != null && Gamepad.get(i).connected) {
                    gamepadConnect(i);
                }
            }

            Gamepad.notifyOnConnect(gamepadConnect, gamepadDisconnect);

            // Gamepad.removeConnect()

            setFullscreenShader(makeBasePipelineShader());
            setBackbufferShader(makeBasePipelineShader());

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

            // resize the camera if we use the `Full` scale mode.
            if (scaleMode == Full) {
                s.camera.width = size.x;
                s.camera.height = size.y;
            }
        }
        scenes = scenes.filter((s) -> !s._destroyed);

        // after the scenes to clear `justPressed`
        keys.update(UPDATE_TIME);
        mouse.update(UPDATE_TIME);
        surface.update(UPDATE_TIME);
        for (g in gamepads.list) {
            g.update(UPDATE_TIME);
        }

        currentTime = now;
    }

    function render (framebuffer:Framebuffer) {
        size.set(framebuffer.width, framebuffer.height);

        for (s in 0...scenes.length) {
            scenes[s].render(framebuffer.g2, framebuffer.g4, s == 0);
        }
    }

    function renderScaled (framebuffer:Framebuffer) {
        size.set(framebuffer.width, framebuffer.height);

        for (s in 0...scenes.length) {
            scenes[s].render(backbuffer.g2, backbuffer.g4, s == 0);
        }

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

    function onSurfaceMove (id:Int, x:Int, y:Int) {
        // NOTE: pass in scaling when there is zoom?
        if (scaleMode == PixelPerfect) {
            surface.move(
                id,
                ScalerExp.transformPixelPerfectX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformPixelPerfectY(y, backbuffer, ScreenCanvas.the)
            );
        } else {
            surface.move(
                id,
                ScalerExp.transformX(x, backbuffer, ScreenCanvas.the),
                ScalerExp.transformY(y, backbuffer, ScreenCanvas.the)
            );
        }
    }

    function gamepadConnect (num:Int) {
        final PRESSED_AMOUNT:Float = 0.75;

        trace('notifyConnect', num);

        final padData = Gamepad.get(num);
        final inputItem = new GamepadInput(num, padData.id, padData.vendor);
        gamepads.list.push(inputItem);

        padData.notify((axis:Int, amount:Float) -> {
            switch (axis) {
                case 0: inputItem.axis0 = amount;
                case 1: inputItem.axis1 = amount;
                case 2: inputItem.axis2 = amount;
                case 3: inputItem.axis3 = amount;
                case 4: inputItem.axis4 = amount;
                case 5: inputItem.axis5 = amount;
            }

            if (axis == 0) {
                if (amount > PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickRight, amount);
                } else if (amount < -PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickLeft, amount);
                } else {
                    inputItem.releaseButton(GamepadButton.LeftStickLeft);
                    inputItem.releaseButton(GamepadButton.LeftStickRight);
                }
            } else if (axis == 1) {
#if js
                if (amount > PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickDown, amount);
                } else if (amount < -PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickUp, amount);
#else
                if (amount > PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickUp, amount);
                } else if (amount < -PRESSED_AMOUNT) {
                    inputItem.pressButton(GamepadButton.LeftStickDown, amount);
#end
                } else {
                    inputItem.releaseButton(GamepadButton.LeftStickDown);
                    inputItem.releaseButton(GamepadButton.LeftStickUp);
                }
            }
            // TODO: right stick
        }, (button:Int, amount:Float) -> {
            if (amount > 0) {
                inputItem.pressButton(button, amount);
            } else {
                inputItem.releaseButton(button);
            }
        });
    }

    function gamepadDisconnect (num:Int) {
        trace('notifyConnect - dis', num);
        gamepads.list = gamepads.list.filter((input) -> input.num != num);
        // TODO: get and remove listeners
        // Gamepad.get(num).remove(Gamepad.get(num).axisListeners, Gamepad.get(num).buttonListeners);
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
    public function setBackbufferShader (imageShader:ImageShader) {
        backbufferPipeline = imageShader.pipeline;
    }

    // Set the shader to be used to render the full screen.
    public function setFullscreenShader (imageShader:ImageShader) {
        fullScreenPipeline = imageShader.pipeline;
    }
}
