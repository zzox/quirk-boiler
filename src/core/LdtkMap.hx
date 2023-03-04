package core;

import haxe.Json;

typedef LdtkLevel = {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var tileLayers:Map<String, LdtkLayer>;
    var entities:Map<String, Array<LdtkEntity>>;
}

typedef LdtkLayer = {
    var tileArray:Array<Int>;
    var width:Int;
    var height:Int;
    var tileSize:Int;
}

typedef LdtkEntity = {
    var type:String;
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var properties:Map<String, Dynamic>;
}

class LdtkMap {
    public var levels:Map<String, LdtkLevel> = [];
    // naive, only updates on intialization.
    public var length:Int = 0;

    public function new (blobString:String) {
        final json:Dynamic = Json.parse(blobString);
        for (level in cast(json.levels, Array<Dynamic>)) {
            for (layer in cast(level.layerInstances, Array<Dynamic>)) {
                if (levels[level.identifier] == null) {
                    levels[level.identifier] = {
                        x: level.worldX,
                        y: level.worldY,
                        width: level.pxWid,
                        height: level.pxHei,
                        tileLayers: new Map(),
                        entities: new Map()
                    }
                }

                if (layer.__type == 'Tiles') {
                    final width = layer.__cWid;
                    final height = layer.__cHei;
                    final tileArray = parseGridTiles(Std.int(width * height), layer.gridTiles);

                    levels[level.identifier].tileLayers[layer.__identifier] = {
                        tileArray: tileArray,
                        width: width,
                        height: height,
                        tileSize: layer.__gridSize
                    };
                } else if (layer.__type == 'Entities') {
                    final entities = [];
                    for (entity in cast(layer.entityInstances, Array<Dynamic>)) {
                        final properties = new Map();

                        for (fi in cast(entity.fieldInstances, Array<Dynamic>)) {
                            properties[fi.__identifier] = fi.__value;
                        }

                        entities.push({
                            type: entity.__identifier,
                            x: entity.px[0] + level.worldX,
                            y: entity.px[1] + level.worldY,
                            height: entity.height,
                            width: entity.width,
                            properties: properties
                        });
                    }

                    levels[level.identifier].entities[layer.__identifier] = entities;
                }
            }

            length++;
        }
    }
}

function parseGridTiles (arrayLength:Int, gridTiles:Array<Dynamic>):Array<Int> {
    final array = [for (_ in 0...arrayLength) 0];
    for (tile in gridTiles) array[tile.d[0]] = tile.t + 1;
    return array;
}
