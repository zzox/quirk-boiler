import core.Game;
import core.Types;
import game.scenes.TestScene;

class Main {
	public static function main() {
        new Game(new IntVec2(1600, 900), new TestScene(), PixelPerfect, 'boilerplate', new IntVec2(160, 144));
	}
}
