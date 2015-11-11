function route(pathname, handle, req, resp){
    console.log("[I] Route request: "+ pathname);
    if(typeof handle[pathname] === 'function'){
        handle[pathname](req, resp);
    }else{
        console.log("[I] No request handler found for "+ pathname);
        response.writeHead(404,{"Content-Type":"test/plain"});
        response.write("404 Not Found");
        response.end()
    }
}

exports.route = route;
