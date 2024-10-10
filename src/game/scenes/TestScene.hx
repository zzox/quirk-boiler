package game.scenes;

import core.Scene;
import core.Sprite;
import core.Types;
import kha.Assets;
import kha.Color;

class TestScene extends Scene {
    override function create () {
        final rect = new Sprite(new Vec2(10, 20));
        rect.makeRect(Color.Red, new IntVec2(30, 40));
        addSprite(rect);

        final text = new Sprite(new Vec2(50, 50));
        text.makeText('We made it!', Assets.fonts.nope_6p, 16);
        addSprite(text);
    }
}
