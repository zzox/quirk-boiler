import core.Game;
import core.Types;
import game.scenes.TestScene;

class Main {
	public static function main() {
        new Game(new IntVec2(1300, 750), new TestScene(), PixelPerfect, 'boilerplate', new IntVec2(320, 180));
	}
}
