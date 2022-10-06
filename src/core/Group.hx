package core;

import core.Sprite;
import core.Types;

/**
    Sprite with children.
**/
class Group extends Sprite {
    var index:Int = 0;

    public function new (?children:Array<Sprite>) {
        super(new Vec2(0, 0), null, new IntVec2(1, 1));

        if (children != null) {
            _children = children;
        }
    }

    public function getNext () {
        if (++index >= _children.length) {
            index = 0;
        }

        return _children[index];
    }

    public function stopAll () {
        for (child in _children) {
            child.stop();
        }
    }
}
