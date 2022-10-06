package core;

import core.Tweens;
import kha.graphics2.Graphics;

// parent scene
class Scene {
    // store a reference to the parent game
    public var game:Game;

    // this scene's sprites
    public var sprites:Array<Sprite> = [];

    // this scene's timers
    public var timers:Timers;

    // this scene's tweens
    public var tweens:Tweens;

    // Initialize objects belonging to the Scene.
    public function new () {
        timers = new Timers();
        tweens = new Tweens();
    }

    // base create, called right before scene starts
    public function create () {}

    // update the state, pass in elapsed time.
    public function update (delta:Float) {
        timers.update(delta);
        tweens.update(delta);

        for (sprite in sprites) {
            sprite.update(delta);
        }
    }

    // called when drawing, passes in graphics instance
    public function render (graphics:Graphics, camera:Camera) {
        for (sprite in sprites) {
            sprite.render(graphics, camera);
        }
    }

#if debug_physics
    // called when drawing, passes in graphics instance
    public function renderDebug (graphics:Graphics, camera:Camera) {
        for (sprite in sprites) {
            sprite.renderDebug(graphics, camera);
        }
    }
#end

    // add a sprite to the scene
    public function addSprite (sprite:Sprite) {
        sprites.push(sprite);
        sprite.scene = this;
        // ATTN: only one layer, needs to be recursive if we want to be nested
        for (child in sprite._children) {
            child.scene = this;
        }
    }

    // remove a sprite from the scene
    public function removeSprite (sprite:Sprite) {
        sprites.remove(sprite);
    }

    // Destroy everything, called right before the scene switches.
    public function destroy () {
        timers.destroy();
        tweens.destroy();

        for (sprite in sprites) {
            sprite.destroy();
            sprite = null;
        }
    }
}
