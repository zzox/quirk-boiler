package core;

function empty () {}

enum TweenType {
    Once;
    Repeats;
    PingPong;
}

// from: easings.net
typedef Easing = Float -> Float;

function linear (input:Float):Float
    return input;

function easeInQuad (input:Float):Float
    return input * input;

function easeOutQuad (input:Float):Float
    return 1.0 - (1.0 - input) * (1.0 - input);

function easeInCubic (input:Float):Float
    return input * input * input;

function easeOutCubic (input:Float):Float
    return 1.0 - Math.pow(1.0 - input, 3);

// TODO: add reflected tweens?
class Tweens {
    var items:Array<Tween> = [];

    public function new () {}

    public function update (delta:Float) {
        for (tween in items) {
            tween.update(delta);
        }

        items = items.filter((item) -> !item.destroyed);
    }

    public function addTween (tween:Tween) {
        items.push(tween);
    }

    public function destroy () {
        for (timer in items) {
            timer.destroy();
            timer = null;
        }
    }
}

class Tween {
    public var type:TweenType = Once;
    public var destroyed:Bool = false;
    public var elapsed:Float = 0.0;
    public var forwards:Bool = true;
    public var time:Float;
    public var callback:Void -> Void;
    public var from:Float;
    public var to:Float;
    public var value:Float;
    public var ease:Easing;

    public function new (from:Float, to:Float, time:Float, ?callback:Void -> Void, ?ease:Float -> Float) {
        this.time = time;
        this.callback = callback;
        this.from = from;
        this.to = to;
        this.ease = ease == null ? linear : ease;
        value = from;
    }

    public function update (delta:Float) {
        elapsed += delta;
        if (elapsed >= time) {
            if (type == Once) {
                if (callback != null) {
                    callback();
                }
                destroy();
            } else if (type == PingPong) {
                forwards = !forwards;
                elapsed -= time;
            } else if (type == Repeats) {
                elapsed -= time;
            }

            value = from;
        }

        value = from + (to - from) * (forwards ? ease(elapsed / time) : 1 - ease(elapsed / time));
    }

    public function destroy () {
        destroyed = true;
        callback = empty;
    }
}
