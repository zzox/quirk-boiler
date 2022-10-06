package core;

import core.Types;
import core.Util;
import kha.Color;

class Camera {
    // for now these will stay 0.
    public var x:Int = 0;
    public var y:Int = 0;
    public var scroll:Vec2;
    public var scale:Vec2 = new Vec2(1, 1);
    public var height:Int;
    public var width:Int;
    public var bgColor:kha.Color = Color.Black;
    var follow:Null<Sprite> = null;
    var followOffset:IntVec2 = new IntVec2(0, 0);
    var bounds:Null<Rect> = null;

    public function new (x:Int, y:Int, width:Int, height:Int) {
        scroll = new Vec2(x, y);
        this.height = height;
        this.width = width;
    }

    public function update (delta:Float) {
        // TODO: handle the scale from camera
        if (follow != null) {
            scroll.x = follow.getMidpoint().x - (width / 2) / scale.x;
            scroll.y = follow.getMidpoint().y - (height / 2) / scale.y;
            scroll.x -= followOffset.x;
            scroll.y -= followOffset.y;
        }

        if (bounds != null) {
            scroll.set(
                clamp(scroll.x, bounds.x, bounds.x + bounds.width - width),
                clamp(scroll.y, bounds.y, bounds.y + bounds.height - height)
            );
        }
    }

    public function startFollow (sprite:Sprite, ?offset:IntVec2) {
        follow = sprite;
        if (offset != null) {
            followOffset = offset.clone();
        }
    }

    public function stopFollow () {
        follow = null;
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
