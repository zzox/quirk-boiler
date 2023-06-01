import core.Game;
import core.Types;
import game.scenes.TestScene;

#if kha_html5
import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
import kha.Macros;
#end

class Main {
	public static function main() {
        setFullWindowCanvas();
        new Game(
            new IntVec2(1300, 750),
            new TestScene(),
            PixelPerfect,
            'boilerplate',
            new IntVec2(160, 90)
        );
	}

    // This handles the resizing on our own so we don't rely on kha's.
    // Requires `kha_html5_disable_automatic_size_adjust` define.
    static function setFullWindowCanvas() {
        #if kha_html5
        document.documentElement.style.padding = '0';
        document.documentElement.style.margin = '0';
        document.body.style.padding = '0';
        document.body.style.margin = '0';
        final canvas:CanvasElement = cast document.getElementById(Macros.canvasId());
        canvas.style.display = 'block';
        canvas.style.imageRendering = 'pixelated';
        final resize = function() {
            var w = document.documentElement.clientWidth;
            var h = document.documentElement.clientHeight;
            if (w == 0 || h == 0) {
                w = window.innerWidth;
                h = window.innerHeight;
            }
            canvas.width = Std.int(w);
            canvas.height = Std.int(h);
        }
        window.onresize = resize;
        resize();
        #end
    }
}
