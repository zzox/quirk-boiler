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

function toDegrees (value:Float):Float {
    return value / (Math.PI / 180);
}

function distanceBetween (point1:Vec2, point2:Vec2):Float {
    return Math.sqrt(Math.pow(point1.x - point2.x, 2) + Math.pow(point1.y - point2.y, 2));
}

// from: https://github.com/HaxeFlixel/flixel/blob/dev/flixel/math/FlxVelocity.hx
function velocityFromAngle (angle:Float, velocity:Float):Vec2 {
    final a = toRadians(angle);
    return new Vec2(Math.cos(a) * velocity, Math.sin(a) * velocity);
}

// from: https://stackoverflow.com/questions/2676719/calculating-the-angle-between-a-line-and-the-x-axis
function angleFromPoints (p1:Vec2, p2:Vec2):Float {
    return Math.atan2(p1.y - p2.y, p1.x - p2.x);
}

function average (values:Array<Float>):Float {
    if (values.length == 0) {
        return 0;
    }

    return Lambda.fold(values, (value, tot) -> tot + value, 0) / values.length;
}

function lerp (target:Float, current:Float, percent:Float):Float {
    return current + (target - current) * percent;
}

function fuzzyLerp (target:Float, current:Float, percent:Float, fuzz:Float = 0.001):Float {
    if (Math.abs(current - target) < fuzz) {
        return target;
    }
    return current + (target - current) * percent;
}

// Returns true if two rectangles overlap.
function rectOverlap (
    r1px:Float,
    r1py:Float,
    r1sx:Float,
    r1sy:Float,
    r2px:Float,
    r2py:Float,
    r2sx:Float,
    r2sy:Float
):Bool {
    return r1px + r1sx >= r2px
        && r1px <= r2px + r2sx
        && r1py + r1sy >= r2py
        && r1py <= r2py + r2sy;
}

function pointInRect (px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool {
    return px >= rx && px < rx + rw && py >= ry && py < ry + rh;
}

function shuffle<T> (items:Array<T>): Array<T> {
    for (i in 0...items.length) {
        final index = Math.floor(Math.random() * items.length);
        final temp = items[i];
        items[i] = items[index];
        items[index] = temp;
    }

    return items;
}
