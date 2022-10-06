package core;

import core.Animation;
import core.Object;
import core.Types;
import core.Util;
import kha.Color;
import kha.Image;
import kha.graphics2.Graphics;

typedef Line = {
    var to:Vec2;
    var width:Float;
}

/**
    Base level graphic, can display tiles from a sprite sheet, a rectangle or a
    line.
**/
class Sprite extends Object {
    // If this sprite is drawn, checked in `render()`.
    public var visible:Bool = true;
    // The `rect` bounds (only drawn when image is null).
    public var rect:IntVec2;
    // The `line` bounds (only drawn when image and rect is null).
    public var line:Line;
    // The kha `Image` item to be scaled, positioned and drawn.
    public var image:Null<Image>;
    // The animation controller for this sprite. Selects the tileIndex
    // based on animation data.
    public var animation:Animation;
    // The index of the spritesheet that we will draw.
    public var tileIndex:Int = 0;
    // Sprite's rotation angle in degrees.
    public var angle:Float = 0.0;
    // Scroll factor affected by the camera.
    public var scrollFactor:Vec2 = new Vec2(1, 1);
    // Scale of this sprites size. 1 is actual size.
    public var scale:Vec2;
    // Depth of this sprite, not used currently.
    public var depth:Int = 1;
    // This sprite flipped on the x axis.
    public var flipX:Bool = false;
    // This sprite flipped on the y axis.
    public var flipY:Bool = false;
    // This sprite's alpha channel. (Not used, use color for now).
    public var alpha:Float = 1.0;
    // This sprite's color 16^8 color value.
    public var color:Int = 0xffffffff;
    // This sprite's text string.
    public var text:String;

    public function new (position:Vec2, ?image:Image, ?size:IntVec2) {
        if (image != null && size == null) {
            size = new IntVec2(image.realWidth, image.realHeight);
        }

        super(position, size);
        this.image = image;
        scale = new Vec2(1.0, 1.0);
        animation = new Animation(this);
    }

    // To be extended by others, called from Scene.
    override public function update (delta:Float) {
        super.update(delta);

        animation.update(delta);
    }

    // Draw this sprite.
    public function render (g2:Graphics, camera:Camera) {
        if (visible) {
            g2.color = Math.floor(alpha * 256) * 0x1000000 + color;

            // TODO: remove angle if pushing is less costly than null check
            if (angle != 0.0) {
                g2.pushRotation(toRadians(angle), getMidpoint().x, getMidpoint().y);
            }

            g2.pushTranslation(-camera.scroll.x * scrollFactor.x, -camera.scroll.y * scrollFactor.y);
            g2.pushScale(camera.scale.x, camera.scale.y);

            if (image != null) {
                // draw a cutout of the spritesheet based on the tileindex
                final cols = Std.int(image.width / size.x);
                // TODO: clamp all to int besides camera position
                g2.drawScaledSubImage(
                    image,
                    (tileIndex % cols) * size.x,
                    Math.floor(tileIndex / cols) * size.y,
                    size.x,
                    size.y,
                    x + (flipX ? size.x * scale.x : 0),
                    y + (flipY ? size.y * scale.y : 0),
                    size.x * scale.x * (flipX ? -1 : 1),
                    size.y * scale.y * (flipY ? -1 : 1)
                );

                // NOTE: is it more performant to check for rect or turn the rect into an image?
            } else if (rect != null) {
                g2.fillRect(x, y, rect.x * scale.x, rect.y * scale.y);
            } else if (line != null) {
                g2.drawLine(x, y, line.to.x, line.to.y, line.width);
            } else if (text != null) {
                g2.drawString(text, x, y);
            }

            g2.popTransformation();
            g2.popTransformation();
            if (angle != 0.0) {
                g2.popTransformation();
            }
        }

        for (child in _children) {
            child.render(g2, camera);
        }
    }

#if debug_physics
    // Draw a square around this sprite, or it's PhysicsBody if
    // `this.physicsEnabled = true;`.
    public function renderDebug (g2:Graphics, camera:Camera) {
        g2.color = Color.Magenta;
        g2.pushTranslation(-camera.scroll.x * scrollFactor.x, -camera.scroll.y * scrollFactor.y);
        g2.pushScale(camera.scale.x, camera.scale.y);
        if (physicsEnabled) {
            g2.drawRect(x + offset.x, y + offset.y, body.size.x, body.size.y);
        } else {
            g2.drawRect(x, y, size.x, size.y);
        }
        g2.popTransformation();
        g2.popTransformation();
        g2.color = Color.White;
        for (child in _children) {
            child.renderDebug(g2, camera);
        }
    }
#end

    // ATTN: this will not render if there's an image loaded. maybe redo
    public function makeRect (color:Int, ?rectSize:IntVec2) {
        if (rectSize != null) {
            size = rectSize.clone();
        }
        rect = new IntVec2(size.x, size.y);
        this.color = color;
    }

    // ATTN: ^^
    public function makeLine (to:Vec2, width:Int, color:Int) {
        line = { to: to, width: width };
        this.color = color;
    }

    // Stops sprite from being updated _or_ drawn.
    public function stop () {
        active = false;
        visible = false;
    }

    // Stops sprite being updated _and_ drawn.
    public function start () {
        active = true;
        visible = true;
    }

    // Add a child sprite to this sprite. Used _after_ group is added.
    public function addChild (sprite:Sprite) {
        _children.push(sprite);
        sprite.scene = this.scene;
    }
}
