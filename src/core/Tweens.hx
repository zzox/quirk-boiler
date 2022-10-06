package core;

function empty () {}

enum TweenType {
    Once;
    Repeats;
    PingPong;
}

// TODO: add reflected tweens
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

    public function new (from:Float, to:Float, time:Float, ?callback:Void -> Void) {
        this.time = time;
        this.callback = callback;
        this.from = from;
        this.to = to;
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

        value = from + (to - from) * (forwards ? (elapsed / time) : 1 - (elapsed / time));
    }

    public function destroy () {
        destroyed = true;
        callback = empty;
    }
}
