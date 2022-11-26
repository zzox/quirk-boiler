package core;

import core.Types.IntVec2;
import core.Types.Vec2;
import kha.Assets;
import kha.Color;
import kha.graphics2.Graphics;

class PreloadScene extends Scene {
    var barWidth:Int;
    var barPos:IntVec2;
    var progressRect:Sprite;
    var pro:Float = 0;

    override public function create () {
        barWidth = Std.int(game.camera.width / 2);
        barPos = new IntVec2(Std.int(barWidth / 2), Std.int(game.camera.height * 3 / 4));

        final imageAsset = Assets.images.made_with_kha;

        addSprite(new Sprite(
            new Vec2(game.camera.width / 2 - imageAsset.width / 2, game.camera.height / 4),
            imageAsset
        ));

        final bgRect = new Sprite(barPos.toVec2());
        bgRect.makeRect(0xffa4aaac, new IntVec2(barWidth, 1));
        addSprite(bgRect);

        progressRect = new Sprite(barPos.toVec2());
        addSprite(progressRect);
    }

    override public function updateProgress (progress:Float) {
        if (progress > 0) {
            progressRect.makeRect(0xffe6e6e6, new IntVec2(Std.int(progress * barWidth), 1));
            pro = progress;
        }
    }
}