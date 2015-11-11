var http = require("http");
var url = require("url");


function start(route, handle){
    function onRequest(req, resp){
        var pathName = url.parse(req.url).pathname;
        console.log("Request for "+ pathName +" received.");

        route(pathName, handle, req, resp);
    }

    http.createServer(onRequest).listen(8888);
    console.log("Server has started.");
}

exports.start = start
