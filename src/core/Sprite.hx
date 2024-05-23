package core;

import core.Animation;
import core.Object;
import core.Types;
import core.Util;
import kha.Color;
import kha.Font;
import kha.Image;
import kha.graphics2.Graphics;

enum SpriteType {
    None;
    Image;
    Rect;
    Line;
    Text;
    BitmapText;
    Tilemap;
    NineSliceImage;
}

typedef Line = {
    var to:Vec2;
    var width:Float;
}

typedef NineSliceData = {
    var topLeft:IntVec2;
    var bottomRight:IntVec2;
    var size:IntVec2;
}

/**
    Base level graphic, can display tiles from a sprite sheet, a rectangle or a
    line.
**/
class Sprite extends Object {
    // If this sprite is drawn, checked in `render()`.
    public var visible:Bool = true;
    // This sprite's type.
    var type:SpriteType = None;
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
    // Array of tile integers.
    var tiles:Array<Int>;
    // Size of each tile.
    var tileSize:IntVec2;
    // Width of the map in tiles.
    var mapWidth:Int;
    // This sprite's font.
    var font:Font;
    // This sprite's font size (only for non-bitmap fonts).
    var fontSize:Int;
    // This sprite's bitmap font.
    public var bitmapFont:BitmapFont;
    // The width of the text characters.
    public var textWidth:Int;
    // 4 points in nineslicegrid
    var nineSliceData:NineSliceData;

    public function new (position:Vec2, ?image:Image, ?size:IntVec2) {
        if (image != null && size == null) {
            size = new IntVec2(image.realWidth, image.realHeight);
        }

        super(position, size);
        this.image = image;
        if (image != null) {
            type = Image;
        }
        scale = new Vec2(1.0, 1.0);
        animation = new Animation(this);
    }

    // To be extended by others, called from Scene.
    override public function update (delta:Float) {
        if (active) {
            super.update(delta);
            animation.update(delta);
        }
    }

    // Draw this sprite.
    public function render (g2:Graphics, camera:Camera) {
        // BUG: in the case where alpha is less than 1 / 256 and the color is
        // black (0xff000000), black will be the color instead of a light alpha.
        if (visible) {
            g2.color = Math.floor(alpha * 256) * 0x1000000 + color;

            g2.pushTranslation(-camera.scroll.x * scrollFactor.x, -camera.scroll.y * scrollFactor.y);
            g2.pushRotation(toRadians(angle), getMidpoint().x, getMidpoint().y);
            g2.pushScale(camera.scale.x, camera.scale.y);

            switch (type) {
                case Image:
                    // draw a cutout of the spritesheet based on the tileindex
                    final cols = Std.int(image.width / size.x);
                    // TODO: clamp all to int besides camera position
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x,
                        Math.floor(tileIndex / cols) * size.y,
                        size.x,
                        size.y,
                        Math.floor(x + ((size.x - size.x * scale.x) / 2) + (flipX ? size.x * scale.x : 0)),
                        Math.floor(y + ((size.y - size.y * scale.y) / 2) + (flipY ? size.y * scale.y : 0)),
                        size.x * scale.x * (flipX ? -1 : 1),
                        size.y * scale.y * (flipY ? -1 : 1)
                    );
                case Rect:
                    g2.fillRect(x, y, rect.x * scale.x, rect.y * scale.y);
                case Line:
                    g2.drawLine(x, y, line.to.x, line.to.y, line.width);
                case Text:
                    g2.font = font;
                    g2.fontSize = fontSize;
                    g2.drawString(text, x, y);
                    textWidth = Std.int(font.width(fontSize, text));
                case BitmapText:
                    final lineHeight = bitmapFont.getFontData().lineHeight;
                    var scrollPos:Int = 0;
                    var xPos:Int = Math.floor(x);
                    var yPos:Int = Math.floor(y);
                    for (char in text.split('')) {
                        final charData = bitmapFont.getCharData(char);

                        // most font types should be exact, construct 3's can wrap.
                        final destX = charData.dest.x % image.realWidth;
                        final destY = charData.dest.y + charData.dest.height *
                            Math.floor(charData.dest.x / image.realWidth);

                        g2.drawSubImage(
                            image,
                            xPos + scrollPos,
                            yPos + lineHeight + charData.yOffset,
                            destX,
                            destY,
                            charData.dest.width,
                            charData.dest.height
                        );

                        scrollPos += charData.width;
                    }
                    textWidth = scrollPos;
                case Tilemap:
                    final cols = Math.floor(image.width / tileSize.x);
                    for (tile in 0...tiles.length) {
                        final tileNum = tiles[tile] - 1;
                        if (tileNum >= 0) {
                            g2.drawScaledSubImage(
                                image,
                                (tileNum % cols) * tileSize.x,
                                Math.floor(tileNum / cols) * tileSize.y,
                                tileSize.x,
                                tileSize.y,
                                x + (tile % mapWidth) * tileSize.x,
                                y + Math.floor(tile / mapWidth) * tileSize.y,
                                tileSize.x * scale.x * (flipX ? -1 : 1),
                                tileSize.y * scale.y * (flipY ? -1 : 1)
                            );
                        }
                    }
                case NineSliceImage:
                    final cols = Std.int(image.width / size.x);

                    // Upper-left quadrant
                    g2.drawSubImage(
                        image,
                        x,
                        y,
                        (tileIndex % cols) * size.x,
                        Math.floor(tileIndex / cols) * size.y,
                        nineSliceData.topLeft.x,
                        nineSliceData.topLeft.y
                    );

                    // Upper-middle quadrant
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x + nineSliceData.topLeft.x,
                        Math.floor(tileIndex / cols) * size.y,
                        nineSliceData.bottomRight.x - nineSliceData.topLeft.x,
                        nineSliceData.topLeft.y,
                        x + nineSliceData.topLeft.x,
                        y,
                        nineSliceData.size.x - nineSliceData.topLeft.x - (size.x - nineSliceData.bottomRight.x),
                        nineSliceData.topLeft.y
                    );

                    // Upper-right quadrant
                    g2.drawSubImage(
                        image,
                        x + (nineSliceData.size.x - (size.x - nineSliceData.bottomRight.x)),
                        y,
                        (tileIndex % cols) * size.x + nineSliceData.bottomRight.x,
                        Math.floor(tileIndex / cols) * size.y,
                        size.x - nineSliceData.bottomRight.x,
                        nineSliceData.topLeft.y
                    );

                    // Middle-left quadrant
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.topLeft.y,
                        nineSliceData.topLeft.x,
                        nineSliceData.bottomRight.y - nineSliceData.topLeft.y,
                        x,
                        y + nineSliceData.topLeft.y,
                        nineSliceData.topLeft.x,
                        nineSliceData.size.y - nineSliceData.topLeft.y - (size.y - nineSliceData.bottomRight.y)
                    );

                    // Middle-middle quadrant
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x + nineSliceData.topLeft.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.topLeft.y,
                        nineSliceData.bottomRight.x - nineSliceData.topLeft.x,
                        nineSliceData.bottomRight.y - nineSliceData.topLeft.y,
                        x + nineSliceData.topLeft.x,
                        y + nineSliceData.topLeft.y,
                        nineSliceData.size.x - nineSliceData.topLeft.x - (size.x - nineSliceData.bottomRight.x),
                        nineSliceData.size.y - nineSliceData.topLeft.y - (size.y - nineSliceData.bottomRight.y)
                    );

                    // Middle-right quadrant
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x + nineSliceData.bottomRight.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.topLeft.y,
                        size.x - nineSliceData.bottomRight.x,
                        nineSliceData.bottomRight.y - nineSliceData.topLeft.y,
                        x + nineSliceData.size.x - (size.x - nineSliceData.bottomRight.x),
                        y + nineSliceData.topLeft.y,
                        size.x - nineSliceData.bottomRight.x,
                        nineSliceData.size.y - nineSliceData.topLeft.y - (size.y - nineSliceData.bottomRight.y)
                    );

                    // Bottom-left quadrant
                    g2.drawSubImage(
                        image,
                        x,
                        y + (nineSliceData.size.y - (size.y - nineSliceData.bottomRight.y)),
                        (tileIndex % cols) * size.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.bottomRight.y,
                        nineSliceData.topLeft.x,
                        size.y - nineSliceData.bottomRight.y
                    );

                    // Bottom-middle quadrant
                    g2.drawScaledSubImage(
                        image,
                        (tileIndex % cols) * size.x + nineSliceData.topLeft.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.bottomRight.y,
                        nineSliceData.bottomRight.x - nineSliceData.topLeft.x,
                        size.y - nineSliceData.bottomRight.y,
                        x + nineSliceData.topLeft.x,
                        y + (nineSliceData.size.y - (size.y - nineSliceData.bottomRight.y)),
                        nineSliceData.size.x - nineSliceData.topLeft.x - (size.x - nineSliceData.bottomRight.x),
                        size.y - nineSliceData.bottomRight.y
                    );

                    // Bottom-right quadrant
                    g2.drawSubImage(
                        image,
                        x + (nineSliceData.size.x - (size.x - nineSliceData.bottomRight.x)),
                        y + (nineSliceData.size.y - (size.y - nineSliceData.bottomRight.y)),
                        (tileIndex % cols) * size.x + nineSliceData.bottomRight.x,
                        Math.floor(tileIndex / cols) * size.y + nineSliceData.bottomRight.y,
                        size.x - nineSliceData.bottomRight.x,
                        size.y - nineSliceData.bottomRight.y
                    );
                case None: null;
            }

            g2.popTransformation();
            g2.popTransformation();
            g2.popTransformation();

            for (child in _children) {
                child.render(g2, camera);
            }
        }
    }

#if debug_physics
    // Draw a square around this sprite, or it's PhysicsBody if
    // `this.physicsEnabled = true;`.
    public function renderDebug (g2:Graphics, camera:Camera) {
        g2.color = Color.Magenta;
        g2.pushTranslation(-camera.scroll.x * scrollFactor.x, -camera.scroll.y * scrollFactor.y);
        g2.pushScale(camera.scale.x, camera.scale.y);
        g2.drawRect(x + offset.x, y + offset.y, body.size.x, body.size.y);
        g2.popTransformation();
        g2.popTransformation();
        g2.color = Color.White;
        for (child in _children) {
            child.renderDebug(g2, camera);
        }
    }
#end

    // Make a rectangle using the current position as top left.
    public function makeRect (color:Int, ?rectSize:IntVec2) {
        if (rectSize != null) {
            size = rectSize.clone();
        }
        rect = new IntVec2(size.x, size.y);
        this.color = color;
        type = Rect;
    }

    // Make a line from this current position to a new point.
    public function makeLine (to:Vec2, width:Int, color:Int) {
        line = { to: to, width: width };
        this.color = color;
        type = Line;
    }

    // Make line of text.
    public function makeText (text:String, font:Font, fontSize:Int) {
        this.text = text;
        this.font = font;
        this.fontSize = fontSize;
        textWidth = Std.int(font.width(fontSize, text));
        type = Text;
    }

    // Make bitmap text. No font sizes on bitmap text.
    public function makeBitmapText (text:String, font:BitmapFont) {
        this.text = text;
        this.bitmapFont = font;
        textWidth = bitmapFont.getTextWidth(text);
        type = BitmapText;
    }

    public function setBitmapText (text:String) {
        this.text = text;
        textWidth = bitmapFont.getTextWidth(text);
    }

    // Make a tilemap. (mapWidth is in tiles not pixels)
    public function makeTilemap (tiles:Array<Int>, tileSize:IntVec2, mapWidth:Int) {
        this.tiles = tiles;
        this.tileSize = tileSize;
        this.mapWidth = mapWidth;
        type = Tilemap;
    }

    // make a nine slize image. does not scale or flip.
    public function makeNineSliceImage (size:IntVec2, topLeft:IntVec2, bottomRight:IntVec2) {
        nineSliceData = {
            size: size,
            topLeft: topLeft,
            bottomRight: bottomRight
        }
        type = NineSliceImage;
    }

    // Stops sprite from being updated _or_ drawn.
    public function stop () {
        active = false;
        visible = false;
    }

    // Starts sprite being updated _and_ drawn.
    public function start () {
        active = true;
        visible = true;
    }

    // Add a child sprite to this sprite. Used _after_ group is added.
    public function addChild (sprite:Sprite) {
        _children.push(sprite);
        sprite.scene = this.scene;
    }

    public function removeChild (sprite:Sprite) {
        sprite.scene = null;
        _children.remove(sprite);
    }
}
