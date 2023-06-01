package core;

function sendErrorLogs (data:String) {
#if sends_metrics
#if localhost
    final url = 'http://localhost:8000/logs/errors';
#else
    final url = 'https://zzox.net/logs/errors';
#end
    final r = new Http(url);
    r.async = true;
    r.setHeader('Content-Type', 'application/json');
    r.setPostData(Json.stringify({ data: data }));
    r.request(true);
    r.onStatus = (stats) -> trace('metrics stats', stats);
    r.onError = (error) -> trace('metrics error', error);
#end
}
