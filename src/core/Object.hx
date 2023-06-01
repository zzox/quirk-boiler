package core;

import core.Physics;
import core.Types;

/**
    Object with basic propertoes, not used as often as `Sprite`. Is not drawn.
**/
class Object {
    // If this object is updated.
    public var active:Bool = true;
    // If this object has been destroyed.  Will be cleaned up if true.
    public var destroyed:Bool = false;
    // Scene this object belongs to.
    public var scene:Scene;
    // Object's x value.
    public var x:Float;
    // Object's y value.
    public var y:Float;
    // Size of this object in x and y values.
    public var size:IntVec2;
    // offset from the top left of the tile image to the top left of the body
    // TODO: should the offset be on the body?
    public var offset:IntVec2 = new IntVec2(0, 0);
    // This object's physics body, can this object's position.
    public var body:PhysicsBody;
    // True if physics is enabled.
    public var physicsEnabled:Bool = false;
    // Child sprites. TODO: move to `Sprite`?
    public var _children:Array<Sprite> = [];

    public function new (position:Vec2, ?size:IntVec2) {
        x = position.x;
        y = position.y;
        this.size = size == null ? new IntVec2(16, 16) : size;
        body = new PhysicsBody(this, this.size, position);
    }

    // Update this object and it's children.
    public function update (delta:Float) {
        if (active) {
            if (physicsEnabled) {
                body.update(delta);
            }

            for (child in _children) {
                if (child.active) {
                    child.update(delta);
                }
            }
        }

        _children = _children.filter((sprite) -> !sprite.destroyed);
    }

    // Set position of this object and it's physics body.
    public function setPosition (_x:Float, _y:Float) {
        x = _x;
        y = _y;
        body.position.set(x + offset.x, y + offset.y);
    }

    // Destroy this object, it's irreversable. Use `active` otherwise.
    public function destroy () {
        destroyed = true;
        for (child in _children) {
            child.destroy();
            child = null;
        }
    }

    // Clones txhe x and y value of the middle of this sprite.
    public function getMidpoint ():Vec2 {
        return new Vec2(
            Std.int(x + (size.x / 2)),
            Std.int(y + (size.y / 2))
        );
    }
}
