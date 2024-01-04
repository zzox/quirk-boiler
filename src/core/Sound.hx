package core;

import kha.audio1.Audio;
import kha.audio1.AudioChannel;

class Sound {
    // Play the sound immediately, returns a new AudioChannel if one exists.
    // NOTE: this is bad and shoudn't be this way.
    public static function play (sound:kha.Sound, volume:Float = 1.0, loop:Bool = false):Null<AudioChannel> {
        final channel = Audio.play(sound, loop);
        if (channel != null) {
            channel.volume = volume;
            return channel;
        }

        return null;
    }

    // Returns a new AudioChannel than can be `play()`ed, `pause()`d, etc.
    public static function load (sound:kha.Sound, volume:Float = 1.0, loop:Bool = false):AudioChannel {
        final channel = Audio.play(sound, loop);
        channel.volume = volume;
        channel.pause();
        return channel;
    }

    // Stream uncompressed audio. Returns an AudioChannel. (Some items are not immediately available)
    public static function stream (sound:kha.Sound, volume:Float = 1.0, loop:Bool = false):AudioChannel {
        final channel = Audio.stream(sound, loop);
        // TODO: test this more thoroughly.
        if (channel == null) {
            throw 'Cannot stream';
        }

        channel.volume = volume;
        return channel;
    }
}
