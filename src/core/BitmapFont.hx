package core;

import core.Types;

typedef CharData = {
    var dest:IntRect; // destination in source image
    var width:Int; // width of character
    var yOffset:Int; // offset in y pixels
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
                width: spacingHash[char],
                yOffset: 0
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
            width: charSize.x,
            yOffset: 0
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

function getFntCharMap (tokens:Array<String>):Map<String, Int> {
    final map = new Map();
    for (s in tokens) {
        if (s != 'char') {
            final items = s.split('=');
            map[items[0]] = Std.parseInt(items[1]);
        }
    }
    return map;
}

// from snowb.org
class FntBitmapFont implements BitmapFont {
    var lineHeight:Int;
    // var charSize:IntVec2;
    var charMap:Map<String, CharData> = new Map();

    public function new (textString:String) {
        final lines = textString.split('\n');
        for (l in lines) {
            final tokens = l.split(' ');

            // lineHeight here isn't how it's used the rest of this engine.
            if (tokens[0] == 'common') {
                final fntMap = getFntCharMap(tokens);
                lineHeight = fntMap['lineHeight'];
            }

            if (tokens[0] == 'char') {
                final fntMap = getFntCharMap(tokens);
                charMap.set(asciiMap[fntMap['id']], {
                    dest: {
                        x: fntMap['x'],
                        y: fntMap['y'],
                        width: fntMap['width'],
                        height: fntMap['height']
                    },
                    width: Std.int(fntMap['xadvance']) - Std.int(fntMap['xoffset']) - 1,
                    yOffset: fntMap['yoffset']
                });
            }
        }
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
        return { lineHeight: 0 };
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

final asciiMap:Map<Int, String> = [
    32 => ' ',
    33 => '!',
    34 => '"',
    35 => '#',
    36 => '$',
    37 => '%',
    38 => '&',
    39 => '\'',
    40 => '(',
    41 => ')',
    42 => '*',
    43 => '+',
    44 => ',',
    45 => '-',
    46 => '.',
    47 => '/',
    48 => '0',
    49 => '1',
    50 => '2',
    51 => '3',
    52 => '4',
    53 => '5',
    54 => '6',
    55 => '7',
    56 => '8',
    57 => '9',
    58 => ':',
    59 => ';',
    60 => '<',
    61 => '=',
    62 => '>',
    63 => '?',
    64 => '@',
    65 => 'A',
    66 => 'B',
    67 => 'C',
    68 => 'D',
    69 => 'E',
    70 => 'F',
    71 => 'G',
    72 => 'H',
    73 => 'I',
    74 => 'J',
    75 => 'K',
    76 => 'L',
    77 => 'M',
    78 => 'N',
    79 => 'O',
    80 => 'P',
    81 => 'Q',
    82 => 'R',
    83 => 'S',
    84 => 'T',
    85 => 'U',
    86 => 'V',
    87 => 'W',
    88 => 'X',
    89 => 'Y',
    90 => 'Z',
    91 => '[',
    92 => '\\',
    93 => ']',
    94 => '^',
    95 => '_',
    96 => '`',
    97 => 'a',
    98 => 'b',
    99 => 'c',
    100 => 'd',
    101 => 'e',
    102 => 'f',
    103 => 'g',
    104 => 'h',
    105 => 'i',
    106 => 'j',
    107 => 'k',
    108 => 'l',
    109 => 'm',
    110 => 'n',
    111 => 'o',
    112 => 'p',
    113 => 'q',
    114 => 'r',
    115 => 's',
    116 => 't',
    117 => 'u',
    118 => 'v',
    119 => 'w',
    120 => 'x',
    121 => 'y',
    122 => 'z',
    123 => '{',
    124 => '|',
    125 => '}',
    126 => '~'
];
