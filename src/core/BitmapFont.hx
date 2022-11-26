package core;

import core.Types;

typedef CharData = {
    var dest:IntRect; // destination in source image
    var width:Int; // width of character
}

typedef FontData = {
    var lineHeight:Int;
}

interface BitmapFont {
    // get the position of the character
    function getCharData (charString:String):CharData;

    public function getFontData ():FontData;

    public function getTextWidth (text:String):Int;
}

class ConstructBitmapFont implements BitmapFont {
    var lineHeight:Int;
    // var charSize:IntVec2;
    var charMap:Map<String, CharData> = new Map();

    public function new (charSize:IntVec2, chars:String, spacingData:Array<Array<Dynamic>>, lineHeight:Int) {
        final spacingHash = new Map<String, Int>();
        for (spaceItems in spacingData) {
            final space = spaceItems[0];
            final items:Array<String> = spaceItems[1].split('');
            for (char in items) {
                spacingHash.set(char, space);
            }
        }

        for (char in chars.split('')) {
            charMap.set(char, {
                dest: {
                    x: chars.indexOf(char) * charSize.x,
                    y: 0,
                    width: charSize.x,
                    height: charSize.y
                },
                width: spacingHash[char]
            });
        }

        this.lineHeight = lineHeight;
    }

    // Get data about the character from this font.
    public function getCharData (charString:String):CharData {
        final char = charString.charAt(0);

        // TODO: remove?
        if (char == null) {
            throw 'No char found!';
        }

        return charMap[char];
    }

    // Get data about this font.
    public function getFontData ():FontData {
        return { lineHeight: lineHeight };
    }

    // get the width of a set of characters
    public function getTextWidth (text:String):Int {
        return Lambda.fold(
            text.split('').map((char) -> getCharData(char).width),
            (item:Int, result) -> result + item,
            0
        );
    }
}
