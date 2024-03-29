package game.scenes;

import core.Camera;
import core.Scene;
import kha.Assets;
import kha.Color;
import kha.graphics2.Graphics;

class TestScene extends Scene {
    override function update (delta:Float) {
        super.update(delta);
    }

    override function render (g2:Graphics) {
        super.render(g2);

        g2.color = Color.Red;
        g2.drawRect(10, 20, 30, 40);

        g2.color = Color.White;
        g2.font = Assets.fonts.nope_6p;
        g2.fontSize = 16;
        g2.drawString('We made it!', 50, 50);
    }
}
