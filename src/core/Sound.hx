package core;

import kha.audio1.Audio;
import kha.audio1.AudioChannel;

class Sound {
    // Play the sound immediately, returns a new AudioChannel.
    public static function play (sound:kha.Sound, volume:Float = 1.0, loop:Bool = false):AudioChannel {
        final channel = Audio.play(sound, loop);
        channel.volume = volume;
        return channel;
    }

    // Returns a new AudioChannel than can be `play()`ed, `pause()`d, etc.
    public static function load (sound:kha.Sound, volume:Float = 1.0, loop:Bool = false):AudioChannel {
        final channel = Audio.play(sound, loop);
        channel.volume = volume;
        channel.pause();
        return channel;
    }
}
