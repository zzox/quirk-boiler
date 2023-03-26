package core;

import core.Types;
import core.Util;
import kha.Color;

class Camera {
    static inline final MIN_LERP_DISTANCE = 60 / 1000;
    // for now these will stay 0.
    // public var x:Int = 0;
    // public var y:Int = 0;
    public var scroll:Vec2;
    public var scale:Vec2 = new Vec2(1, 1);
    public var height:Int;
    public var width:Int;
    public var bgColor:kha.Color = Color.Black;
    public var followX:Null<Sprite> = null;
    public var followY:Null<Sprite> = null;
    public var followOffset:IntVec2 = new IntVec2(0, 0);
    public var followLerp:Vec2 = new Vec2(1.0, 1.0);
    var bounds:Null<Rect> = null;

    public function new (x:Int, y:Int, width:Int, height:Int) {
        scroll = new Vec2(x, y);
        this.height = height;
        this.width = width;
    }

    public function update (delta:Float) {
        // TODO: handle the scale from camera
        if (followX != null) {
            final targetX = followX.getMidpoint().x - (width / 2) / scale.x;
            var diffX = lerp(targetX, scroll.x, followLerp.x);

            if (Math.abs(diffX) < MIN_LERP_DISTANCE) {
                diffX = targetX - scroll.x;
            }

            scroll.x = diffX;
            scroll.x -= followOffset.x;
        }

        if (followY != null) {
            final targetY = followY.getMidpoint().y - (height / 2) / scale.y;
            var diffY = lerp(targetY, scroll.y, followLerp.y);

            if (Math.abs(diffY) < MIN_LERP_DISTANCE) {
                diffY = targetY - scroll.y;
            }

            scroll.y = diffY;
            scroll.y -= followOffset.y;
        }

        if (bounds != null) {
            scroll.set(
                clamp(scroll.x, bounds.x, bounds.x + bounds.width - width),
                clamp(scroll.y, bounds.y, bounds.y + bounds.height - height)
            );
        } else {
            scroll.set(scroll.x, scroll.y);
        }
    }

    public function startFollow (sprite:Sprite, ?offset:IntVec2, ?lerp:Vec2) {
        followX = sprite;
        followY = sprite;
        if (offset == null) {
            followOffset = new IntVec2(0, 0);
        } else {
            followOffset = offset.clone();
        }

        if (lerp == null) {
            followLerp = new Vec2(1.0, 1.0);
        } else {
            followLerp = lerp.clone();
        }
    }

    public function stopFollow () {
        followX = null;
        followY = null;
        followOffset = null;
    }

    public function setBounds (x:Int, y:Int, width:Int, height:Int) {
        bounds = {
            x: x,
            y: y,
            width: width,
            height: height
        }
    }
}
