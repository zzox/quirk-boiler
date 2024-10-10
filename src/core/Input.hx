package core;

import core.Types;
import kha.input.KeyCode;

enum abstract MouseButton(Int) to Int {
    var Left = 0;
    var Right = 1;
}

typedef MouseButtonData = {
    var button:Int;
    var time:Float;
}

class Input {
    public function new () {}
}

// LATER: move to separate static classes/maps; mouse, keys, gamepad
// TODO: event listeners
    // potentially one that can stop propagation and not fire off to others?
class MouseInput extends Input {
    var _pressed:Array<MouseButtonData> = [];
    var _justPressed:Array<Int> = [];
    var _justReleased:Array<Int> = [];

    public var screenPos:IntVec2 = new IntVec2(-1, -1);
    public var position:IntVec2 = new IntVec2(-1, -1);

    public function pressMouse (button:Int, _x:Int, _y:Int) {
        _pressed.push({ button: button, time: 0.0 });
        _justPressed.push(button);
    }

    public function releaseMouse (button:Int, _x:Int, _y:Int) {
        _pressed = _pressed.filter((p) -> p.button != button);
        _justReleased.push(button);
    }

    public function mouseMove (x:Int, y:Int, moveX:Int, moveY:Int) {
        screenPos.x = x;
        screenPos.y = y;
    }

    public function setMousePos (x:Int, y:Int) {
        position.x = x;
        position.y = y;
    }

    public function update (delta:Float) {
        _justPressed = [];
        _justReleased = [];
        for (btn in _pressed) { btn.time += delta; };
    }

    public function pressed (button:MouseButton):Bool {
        return (_pressed.filter((p) -> p.button == button)).length == 1;
    }

    public function justPressed (button:MouseButton):Bool {
        return _justPressed.contains(button);
    }

    public function justReleased (button:MouseButton):Bool {
        return _justReleased.contains(button);
    }
}

typedef KeyButtonData = {
    var code:KeyCode;
    var time:Float;
}

class KeysInput extends Input {
    var _pressed:Array<KeyButtonData> = [];
    var _justPressed:Array<KeyCode> = [];
    var _justReleased:Array<KeyCode> = [];

    public function pressButton (code:KeyCode) {
        if ((_pressed.filter((p) -> p.code == code)).length > 0) {
            return;
        }

        _pressed.push({ code: code, time: 0.0 });
        _justPressed.push(code);
    }

    public function releaseButton (code:KeyCode) {
        _pressed = _pressed.filter((p) -> p.code != code);
        _justReleased.push(code);
    }

    public function update (delta:Float) {
        _justPressed = [];
        _justReleased = [];
        for (btn in _pressed) { btn.time += delta; };
    }

    public function pressed (code:KeyCode):Bool {
        return (_pressed.filter((button) -> button.code == code)).length == 1;
    }

    public function anyPressed (codes:Array<KeyCode>): Bool {
        return (_pressed.filter((button) -> codes.contains(button.code))).length > 0;
    }

    public function justPressed (code:KeyCode):Bool {
        return _justPressed.contains(code);
    }

    public function anyJustPressed (codes:Array<KeyCode>):Bool {
        return (_justPressed.filter((c) -> codes.contains(c))).length > 0;
    }

    public function justReleased (code:KeyCode):Bool {
        return _justReleased.contains(code);
    }

    public function anyJustReleased (codes:Array<KeyCode>):Bool {
        return (_justReleased.filter((c) -> codes.contains(c))).length > 0;
    }

    public function longestHeld (codes:Array<KeyCode>):Null<KeyButtonData> {
        return Lambda.fold(
            _pressed.filter((button) -> codes.contains(button.code)),
            (item:KeyButtonData, result:Null<KeyButtonData>) -> {
                if (result == null || item.time > result.time) {
                    return item;
                }

                return result;
            },
            null
        );
    }

    public function shortestHeld (codes:Array<KeyCode>):Null<KeyButtonData> {
        return Lambda.fold(
            _pressed.filter((button) -> codes.contains(button.code)),
            (item:KeyButtonData, result:Null<KeyButtonData>) -> {
                if (result == null || item.time < result.time) {
                    return item;
                }

                return result;
            },
            null
        );
    }
}

enum abstract GamepadButton(Int) to Int {
    var ButtonBottom = 0;
    var ButtonRight = 1;
    var ButtonLeft = 2;
    var ButtonTop = 3;
    var LeftShoulder = 4;
    var RightShoulder = 5;
    var LeftTrigger = 6;
    var RightTrigger = 7;
    var Select = 8;
    var Start = 9;
    var LeftStick = 10;
    var RightStick = 11;
    var PadUp = 12;
    var PadDown = 13;
    var PadLeft = 14;
    var PadRight = 15;
    var HomeButton = 16;
    var LeftStickUp = 96;
    var LeftStickDown = 97;
    var LeftStickLeft = 98;
    var LeftStickRight = 99;
}

typedef GamepadButtonData = {
    var code:Int;
    var amount:Float;
    var time:Float;
}

class Gamepads {
    public var list:Array<GamepadInput> = [];

    public function new () {}

    public function checkAllPressed (code:GamepadButton) {
        for (l in list) {
            if (l.pressed(code)) {
                return true;
            }
        }

        return false;
    }

    public function checkAllJustPressed (code:GamepadButton) {
        for (l in list) {
            if (l.justPressed(code)) {
                return true;
            }
        }

        return false;
    }

    public function checkAllJustReleased (code:GamepadButton) {
        for (l in list) {
            if (l.justReleased(code)) {
                return true;
            }
        }

        return false;
    }

    public function checkAllAnyPressed (codes:Array<GamepadButton>) {
        for (l in list) {
            if (l.anyPressed(codes)) {
                return true;
            }
        }

        return false;
    }

    public function checkAllAnyJustPressed (codes:Array<GamepadButton>) {
        for (l in list) {
            if (l.anyJustPressed(codes)) {
                return true;
            }
        }

        return false;
    }

    public function checkAllAnyJustReleased (codes:Array<GamepadButton>) {
        for (l in list) {
            if (l.anyJustReleased(codes)) {
                return true;
            }
        }

        return false;
    }
}

class GamepadInput extends Input {
    public var num:Int;

    var _pressed:Array<GamepadButtonData> = [];
    var _justPressed:Array<Int> = [];
    var _justReleased:Array<Int> = [];

    public var axis0:Float = 0;
    public var axis1:Float = 0;
    public var axis2:Float = 0;
    public var axis3:Float = 0;
    public var axis4:Float = 0;
    public var axis5:Float = 0;

    public function new (num:Int, id:String, vendor:String) {
        super();
        this.num = num;
        trace(id, vendor);
    }

    public function pressButton (code:Int, amount:Float) {
        final item = _pressed.filter((p) -> p.code == code);
        if (item.length == 1) {
            item[0].amount = amount;
            return;
        }

        _pressed.push({ code: code, time: 0.0, amount: amount });
        _justPressed.push(code);
    }

    public function releaseButton (code:Int) {
        _pressed = _pressed.filter((p) -> p.code != code);
        _justReleased.push(code);
    }

    public function update (delta:Float) {
        _justPressed = [];
        _justReleased = [];
        for (btn in _pressed) { btn.time += delta; };
    }

    public function pressed (code:GamepadButton):Bool {
        return (_pressed.filter((button) -> button.code == code)).length == 1;
    }

    public function anyPressed (codes:Array<GamepadButton>): Bool {
        for (p in _pressed) {
            for (c in codes) {
                if (c == p.code) {
                    return true;
                }
            }
        }
        return false;
        // return (_pressed.filter((button) -> codes.contains(button.code))).length > 0;
    }

    public function justPressed (code:GamepadButton):Bool {
        return _justPressed.contains(code);
    }

    public function anyJustPressed (codes:Array<GamepadButton>):Bool {
        for (p in _justPressed) {
            for (c in codes) {
                if (c == p) {
                    return true;
                }
            }
        }
        return false;
        // return (_justPressed.filter((c) -> codes.contains(c))).length > 0;
    }

    public function justReleased (code:GamepadButton):Bool {
        return _justReleased.contains(code);
    }

    public function anyJustReleased (codes:Array<GamepadButton>):Bool {
        for (p in _justReleased) {
            for (c in codes) {
                if (c == p) {
                    return true;
                }
            }
        }
        return false;
        // return (_justReleased.filter((c) -> codes.contains(c))).length > 0;
    }
}
