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
    // TODO: move to a parent class
    public function getTextWidth (text:String):Int {
        return Lambda.fold(
            text.split('').map((char) -> {
                final charData = getCharData(char);
                if (charData == null) {
                    throw 'Do not have char: ${char}';
                }
                return charData.width;
            }),
            (item:Int, result) -> result + item,
            0
        );
    }
}

final asciiChars = ' !"#$%&*()*+,-./0123456789;:<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[/]^_`abcdefghijklmnopqrstuvwxyz{|}~';
// special type of font for: https://opengameart.org/content/pixel-font-basic-latin-latin-1-box-drawing
class AsciiFont implements BitmapFont {
    var lineHeight:Int;
    var charSize:IntVec2;
    static final charArray:Array<String> = asciiChars.split('');

    public function new (charSize:IntVec2, lineHeight:Int) {
        this.charSize = charSize;
        this.lineHeight = lineHeight;
    }

    // Get data about the character from this font.
    public function getCharData (charString:String):CharData {
        // TODO: remove?
        if (!charArray.contains(charString.charAt(0))) {
            throw 'No char found!';
        }

        return {
            dest: {
                x: charArray.indexOf(charString.charAt(0)) * charSize.x,
                y: 0,
                width: charSize.x,
                height: charSize.y
            },
            width: charSize.x
        };
    }

    // Get data about this font.
    public function getFontData ():FontData {
        return { lineHeight: lineHeight };
    }

    // get the width of a set of characters
    public function getTextWidth (text:String):Int {
        return Lambda.fold(
            text.split('').map((char) -> {
                final charData = getCharData(char);
                if (charData == null) {
                    throw 'Do not have char: ${char}';
                }
                return charData.width;
            }),
            (item:Int, result) -> result + item,
            0
        );
    }
}
