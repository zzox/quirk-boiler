package core;

import core.Types;

// make these static methods on a class?
function clamp (value:Float, min:Float, max:Float):Float {
    if (value < min) {
        return min;
    } else if (value > max) {
        return max;
    }

    return value;
}

function intClamp (value:Int, min:Int, max:Int):Int {
    if (value < min) {
        return min;
    } else if (value > max) {
        return max;
    }

    return value;
}

function toRadians (value:Float):Float {
    return value * (Math.PI / 180);
}

function distanceBetween (point1:Vec2, point2:Vec2):Float {
    return Math.sqrt(Math.pow(point1.x - point2.x, 2) + Math.pow(point1.y - point2.y, 2));
}

// from: https://github.com/HaxeFlixel/flixel/blob/dev/flixel/math/FlxVelocity.hx
function velocityFromAngle (angle:Float, velocity:Float):Vec2 {
    final a = toRadians(angle);
    return new Vec2(Math.cos(a) * velocity, Math.sin(a) * velocity);
}

function average (values:Array<Float>):Float {
    if (values.length == 0) {
        return 0;
    }

    return Lambda.fold(values, (value, tot) -> tot + value, 0) / values.length;
}

function lerp (target:Float, current:Float, percent:Float):Float {
    return (target - current) * percent;
}
