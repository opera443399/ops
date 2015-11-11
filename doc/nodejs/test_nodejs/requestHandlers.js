var querystring = require("querystring"),
    fs = require("fs"),
//  $ npm install formidable
    formidable = require("formidable");

function start(req, resp){
    console.log("Request handler -> start");

    var body ='<html>'+
        '<head>'+
        '<meta http-equiv="Content-Type" '+
        'content="text/html; charset=UTF-8" />'+
        '</head>'+
        '<body>'+
        '<form action="/upload" enctype="multipart/form-data" '+
        'method="post">'+
        '<input type="file" name="upload">'+
        '<input type="submit" value="Upload file" />'+
        '</form>'+
        '</body>'+
        '</html>';
    
    resp.writeHead(200,{"Content-Type":"text/html"});
    resp.write(body);
    resp.end();
}

function upload(req, resp){
    console.log("Request handler ->  upload");
    
    var form = new formidable.IncomingForm();
    console.log("about to parse");
    form.parse(req,function(error, fields, files){
        console.log("parsing done");
        fs.renameSync(files.upload.path,"/tmp/test.png");
        resp.writeHead(200,{"Content-Type":"text/html"});
        resp.write("received image:<br />");
        resp.write("<img src='/show' />");
        resp.end();
    });
}

function show(req, resp){
    console.log("Request handler -> show");
    fs.readFile("/tmp/test.png","binary",function(error, file){
        if(error){
            resp.writeHead(500,{"Content-Type":"text/plain"});
            resp.write(error +"\n");
            resp.end();
        }else{
            resp.writeHead(200,{"Content-Type":"image/png"});
            resp.write(file,"binary");
            resp.end();
        }
    });
}



exports.start = start;
exports.upload = upload;
exports.show = show;
