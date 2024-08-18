package core;

typedef AnimItem = {
    var name:String;
    var vals:Array<Int>;
    var frameTime:Float;
    var repeats:Bool;
}

/**
    Sprite's animation manager.
    NOTE: using frameTime instead of fps since it makes more sense to me.
**/
class Animation {
    var spriteRef:Sprite;

    // The map of animation items.
    public var _animations:Map<String, AnimItem> = [];
    // Callback to call on completion of an animation. Won't call if repeats is
    // set to true.
    public var onComplete:String -> Void = (_:String) -> {};
    public var completed:Bool = false;
    var animTime:Float;
    var currentAnim:AnimItem;
    var isPaused = false;

    public function new (spriteRef:Sprite) {
        this.spriteRef = spriteRef;
    }

    // Add an animation with name, frames and time per frame.
    public function add (name:String, vals:Array<Int>, frameTime:Float = 1.0, repeats:Bool = true) {
        _animations[name] = {
            name: name,
            vals: vals,
            frameTime: frameTime,
            repeats: repeats
        };
    }

    // Play animation by name.  Won't restart same anim unless forced.
    public function play (name:String, forceRestart:Bool = false) {
        isPaused = false;
        // NOTE: `|| completed` isn't adequately tested
        if (forceRestart || completed || currentAnim == null || name != currentAnim.name) {
            animTime = 0;
            currentAnim = _animations[name];
            completed = false;
            // HACK: without this a previous anim may play before the sprite is updated.
            spriteRef.tileIndex = currentAnim.vals[0];
        }
    }

    // Update the sprtites tileIndex based on animation.
    public function update (delta:Float) {
        if (currentAnim == null || isPaused) {
            return;
        }

        animTime += delta;

        final frameAnimTime = Math.floor(animTime / currentAnim.frameTime);

        if (!currentAnim.repeats && frameAnimTime >= currentAnim.vals.length) {
            spriteRef.tileIndex = currentAnim.vals[currentAnim.vals.length - 1];
            if (!completed) {
                onComplete(currentAnim.name);
                completed = true;
            }
        } else {
            spriteRef.tileIndex = currentAnim.vals[frameAnimTime % currentAnim.vals.length];
        }
    }

    public function getCurrentAnim ():Null<String> {
        if (currentAnim != null) {
            return currentAnim.name;
        }

        return null;
    }

    public function pause () {
        isPaused = true;
    }
}
