package core;

import core.Types;
import core.Util;

// TODO: mass
/**
    A rectangle that can move and collide with other recangles. Has a parent
    `Object` that it updates based on it's physics properties.
**/
class PhysicsBody {
    // Parent object that this updates.
    public var parent:Object;
    // Width and height of body in x and y.
    public var size:IntVec2;
    // World position of this body.
    public var position:Vec2;
    // Previously updated position of this body.
    public var lastPos:Vec2;
    // If this can be effected by other physics body.
    public var immovable:Bool = false;
    // The multiplier in which gravity effects this body.
    public var gravityFactor:Vec2 = new Vec2(1, 1);
    // The increase of velocity per second.
    public var acceleration:Vec2 = new Vec2(0, 0);
    // The movement of pixels per second.
    public var velocity:Vec2 = new Vec2(0, 0);
    // Maximum velocity.
    public var maxVelocity:Vec2 = new Vec2(1000000, 1000000); // whats a good value for this?
    // The decrease of velocity per second.
    public var drag:Vec2 = new Vec2(0, 0);
    // The decrease of velocity per second.
    public var bounce:Vec2 = new Vec2(0, 0);
    // Boolean values of 4 cardinal directions, true if they are touching
    // another physics body.
    public var touching:DirFlags;
    // Boolean values of 4 cardinal directions, true if they allow collisions
    // from a direction.
    public var collides:DirFlags = {
        left: true,
        right: true,
        up: true,
        down: true
    }

    public function new (parent:Object, size:IntVec2, position:Vec2, immovable:Bool = false) {
        this.parent = parent;
        this.size = size.clone();
        this.position = position.clone();
        this.lastPos = position.clone();
        resetTouchingFlags();
    }

    // Update this physics body with the time since the last update.
    public function update (delta:Float) {
        final pos = new Vec2(position.x, position.y);
        // ATTN: this many references feels weird
        final gravity = parent.scene.game.physics.gravity;

        // calculate increase/decrease velocity based on gravity and acceleration
        var newX = velocity.x + delta * (acceleration.x + (gravity.x * gravityFactor.x));
        var newY = velocity.y + delta * (acceleration.y + (gravity.y * gravityFactor.y));

        // subtract drag
        if (newX > 0) {
            newX = Math.max(0, newX - drag.x * delta);
        }

        if (newX < 0) {
            newX = Math.min(0, newX + drag.x * delta);
        }

        if (newY > 0) {
            newY = Math.max(0, newY - drag.y * delta);
        }

        if (newY < 0) {
            newY = Math.min(0, newY + drag.y * delta);
        }

        // configure velocity around max velocity.
        velocity.set(
            clamp(newX, -maxVelocity.x, maxVelocity.x),
            clamp(newY, -maxVelocity.y, maxVelocity.y)
        );

        // update velocity based on position
        position.set(
            position.x + velocity.x * delta,
            position.y + velocity.y * delta
        );

        updateParent();

        // reset flags here after the scene and sprites have been updated,
        // hopefully after the developer has done what they need with the
        // touching flags.
        resetTouchingFlags();

        lastPos.set(pos.x, pos.y);
    }

    // physics body controls the parents position
    public function updateParent () {
        parent.setPosition(
            position.x - parent.offset.x,
            position.y - parent.offset.y
        );
    }

    public function resetTouchingFlags () {
        touching = {
            left: false,
            right: false,
            up: false,
            down: false
        }
    }

    // TODO: shorthand for x, y, height and width
}

/**
    Physics methods.
    TODO: make these methods static?
**/
class Physics {
    // Worlds gravity on x and y access, all physics bodies check this value.
    public var gravity:IntVec2 = new IntVec2(0, 0);

    // TODO:
    // colliders: array of colliders to call after updating items.

    // TODO: consider static methods?
    public function new () {}

    // Check overlap and then separate two physics bodies. Also updates the
    // parent object.
    public function collide (
        body1:PhysicsBody,
        body2:PhysicsBody,
        ?callback: (body1:PhysicsBody, body2:PhysicsBody) -> {}
    ):Bool {
        var collided = false;

        final doesOverlap = overlap(body1, body2);
        if (doesOverlap) {
            // separate
            if (!body1.immovable && body2.immovable) {
                collided = checkDirectionalCollision(body1, body2, true);
            }

            if (body1.immovable && !body2.immovable) {
                collided = checkDirectionalCollision(body2, body1, true);
            }

            if (!body1.immovable && !body2.immovable) {
                // separate moving
                // (half each of their separations)
                // later, use a mass to calculate the bounce
                throw 'two movable objects, not separating';
            }

            if (callback != null) {
                callback(body1, body2);
            }
        }

        return collided;
    }

    // Returns true if two physics bodies overlap.
    public function overlap (body1:PhysicsBody, body2:PhysicsBody):Bool {
        return body1.position.x + body1.size.x >= body2.position.x
            && body1.position.x <= body2.position.x + body2.size.x
            && body1.position.y + body1.size.y >= body2.position.y
            && body1.position.y <= body2.position.y + body2.size.y;
    }

    // Checks the collision directions and then sets the flags, optionally handles `separate`.
    // https://gamedev.stackexchange.com/questions/13774/how-do-i-detect-the-direction-of-2d-rectangular-object-collisions
    // NOTE: checking a perpedicular direction first may prevent seam-clipping.
    // NOTE: moved the returns outside of the separates checks, may affect backwards-compat.
    public function checkDirectionalCollision (fromBody:PhysicsBody, intoBody:PhysicsBody, separates:Bool):Bool {
        // TODO: something like if abs(velocity.y) > abs(velocity.x) checkLeft(); checkRight();
        if (fromBody.collides.left && intoBody.collides.right
            && fromBody.lastPos.x >= intoBody.position.x + intoBody.size.x
            && fromBody.position.x < intoBody.position.x + intoBody.size.x) {
            fromBody.touching.left = true;
            if (separates) {
                separate(fromBody, intoBody, Left);
            }
            return true;
        }

        if (fromBody.collides.right && intoBody.collides.left
            && fromBody.lastPos.x + fromBody.size.x <= intoBody.position.x
            && fromBody.position.x + fromBody.size.x > intoBody.position.x) {
            fromBody.touching.right = true;
            if (separates) {
                separate(fromBody, intoBody, Right);
            }
            return true;
        }

        if (fromBody.collides.up && intoBody.collides.down
            && fromBody.lastPos.y >= intoBody.position.y + intoBody.size.y
            && fromBody.position.y < intoBody.position.y + intoBody.size.y) {
            fromBody.touching.up = true;
            if (separates) {
                separate(fromBody, intoBody, Up);
            }
            return true;
        }

        if (fromBody.collides.down && intoBody.collides.up
            && fromBody.lastPos.y + fromBody.size.y <= intoBody.position.y
            && fromBody.position.y + fromBody.size.y > intoBody.position.y) {
            fromBody.touching.down = true;
            if (separates) {
                separate(fromBody, intoBody, Down);
            }
            return true;
        }

        return false;
    }

    // remove fromBody from toBody
    function separate (fromBody:PhysicsBody, toBody:PhysicsBody, dir:Dir) {
        switch (dir) {
            case Left:
                fromBody.position.x = toBody.position.x + toBody.size.x;
                fromBody.velocity.x = -fromBody.velocity.x * fromBody.bounce.x;
            case Right:
                fromBody.position.x = toBody.position.x - fromBody.size.x;
                fromBody.velocity.x = -fromBody.velocity.x * fromBody.bounce.x;
            case Up:
                fromBody.position.y = toBody.position.y + toBody.size.y;
                fromBody.velocity.y = -fromBody.velocity.y * fromBody.bounce.y;
            case Down:
                fromBody.position.y = toBody.position.y - fromBody.size.y;
                fromBody.velocity.y = -fromBody.velocity.y * fromBody.bounce.y;
        }

        // parent sprite needs to be updated from the `body`
        // don't like this
        fromBody.updateParent();
    }
}
