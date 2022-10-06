package core;

class Vec2 {
    public var x:Float;
    public var y:Float;

    public function new (x:Float, y:Float) {
        set(x, y);
    }

    public function set (x:Float, y: Float) {
        this.x = x;
        this.y = y;
    }

    public function clone ():Vec2 {
        return new Vec2(x, y);
    }
}

class IntVec2 {
    public var x:Int;
    public var y:Int;

    public function new (x:Int, y:Int) {
        set(x, y);
    }

    public function set (x:Int, y: Int) {
        this.x = x;
        this.y = y;
    }

    public function clone ():IntVec2 {
        return new IntVec2(x, y);
    }

    public function toVec2 ():Vec2 {
        return new Vec2(x, y);
    }
}

typedef Rect = {
    var x:Float;
    var y:Float;
    var height:Float;
    var width:Float;
}

enum Dir {
    Left;
    Right;
    Up;
    Down;
}
