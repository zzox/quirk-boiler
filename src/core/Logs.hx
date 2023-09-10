package core;

import haxe.CallStack;
import haxe.Exception;
import haxe.Http;
import haxe.Json;

final id = (Math.random() + '').split('.')[1];

function formatLogs () {}

function formatStack (stack:CallStack) {
    final s = [];
    for (item in stack) {
        final params = item.getParameters();
        var line = '';

        if (Std.isOfType(params[0], String)) {
            line += params[0];
        } else {
            line += Type.enumParameters(params[0])[0];
            line += '#' + Type.enumParameters(params[0])[1] + ': ';
            line += params.slice(1).join(', ');
        }

        s.push(line);
    }
    return s;
}

function sendLogs (data:String, desc:String) {
#if sends_metrics
#if localhost
    final url = 'http://localhost:8000/logs/boiler';
#else
    final url = 'https://mysite.net/logs/boiler';
#end
    final r = new Http(url);
#if kha_html5
    r.async = true;
#end
    r.setHeader('Content-Type', 'application/json');
    r.setPostData(Json.stringify({ id: id, data: data, desc: desc }));
    r.request(true);
    r.onStatus = (stats) -> trace('metrics stats', stats);
    r.onError = (error) -> trace('metrics error', error);
#end
}

function sendErrorLogs (error:Exception) {
#if sends_metrics
#if localhost
    final url = 'http://localhost:8000/logs/errors';
#else
    final url = 'https://mysite.net/logs/errors';
#end
    final r = new Http(url);
#if kha_html5
    r.async = true;
#end
    r.setHeader('Content-Type', 'application/json');
    r.setPostData(Json.stringify({
        id: id,
        message: error.message,
        stack: formatStack(error.stack),
        project: 'good'
    }));
    r.request(true);
    r.onStatus = (stats) -> trace('metrics stats', stats);
    r.onError = (error) -> trace('metrics error', error);
#end
}
