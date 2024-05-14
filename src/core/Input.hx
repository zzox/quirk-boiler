package core;

import core.Types;
import kha.input.KeyCode;

enum abstract MouseButton(Int) to Int {
    var Left = 0;
    var Right = 1;
}

typedef KeyButtonData = {
    var code:KeyCode;
    var time:Float;
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

class KeysInput extends Input {
    var _pressed:Array<KeyButtonData> = [];
    var _justPressed:Array<KeyCode> = [];
    var _justReleased:Array<KeyCode> = [];

    public function pressButton (code:KeyCode) {
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
