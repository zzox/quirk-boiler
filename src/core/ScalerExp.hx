package core;

import kha.Canvas;
import kha.Color;
import kha.Image;
import kha.math.FastMatrix3;

// only works for no screen rotation!
// from: https://github.com/Kode/Kha/blob/main/Sources/kha/Scaler.hx
class ScalerExp {
    public static function scalePixelPerfect(source:Image, destination:Canvas) {
        var g = destination.g2;
        g.pushTransformation(getPixelPerfectScaledTransformation(source, destination));
        g.color = Color.White;
        g.opacity = 1;
        g.drawImage(source, 0, 0);
        g.popTransformation();
    }

    public static function transformX (x:Int, source:Image, destination:Canvas):Int {
        final scale = getScale(source, destination);
        return Math.floor(
            (x / scale) + (((source.width * scale - destination.width) * 0.5) / scale)
        );
    }

    public static function transformY (y:Int, source:Image, destination:Canvas):Int {
        final scale = getScale(source, destination);
        return Math.floor(
            (y / scale) + (((source.height * scale - destination.height) * 0.5) / scale)
        );
    }

    public static function transformPixelPerfectX (x:Int, source:Image, destination:Canvas):Int {
        final scale = getPixelPerfectScale(source, destination);
        return Math.floor(
            (x / scale) + (((source.width * scale - destination.width) * 0.5) / scale)
        );
    }

    public static function transformPixelPerfectY (y:Int, source:Image, destination:Canvas):Int {
        final scale = getPixelPerfectScale(source, destination);
        return Math.floor(
            (y / scale) + (((source.height * scale - destination.height) * 0.5) / scale)
        );
    }

    static function getPixelPerfectScaledTransformation(source:Image, destination:Canvas):FastMatrix3 {
        final scale = getPixelPerfectScale(source, destination);
        return new FastMatrix3(
            scale, 0, (destination.width - source.width * scale) * 0.5,
            0, scale, (destination.height - source.height * scale) * 0.5,
            0, 0, 1
        );
    }

    static function getScale (source:Image, destination:Canvas):Float {
        return source.width / source.height > destination.width / destination.height
            ? destination.width / source.width
            : destination.height / source.height;
    }

    static function getPixelPerfectScale (source:Image, destination:Canvas):Int {
        final scale = source.width / source.height > destination.width / destination.height
            ? Math.floor(destination.width / source.width)
            : Math.floor(destination.height / source.height);

        if (scale < 1) {
            return 1;
        }

        return scale;
    }
}
