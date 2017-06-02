/*
 * main.js
 * pc.peng @ 20170602
 */


/*
 * 用途：读取 json 文件，生成对应的 html code
 * json_file： json 数据文件路径
 */
function load_data_from_json(json_file){
    $("div#panel_lists").empty();
    $.getJSON(json_file,function(result){
        //console.info(result.data);
        $.each(result.data, function(idx_i, item_i){
            var content = '';
            var img_path = 'static/images/';
            var img_default = 'default.svg';
            
            content = ''
                + '<!-- panel Start-->'
                + '<div class="panel" id="links_online">'
                    + '<div class="panel-heading">'
                        + '<span class="panel-title">'
                            + '<a class="accordion-toggle" data-toggle="collapse" data-parent="#links_online" href="#collapse_' + idx_i + '">'
                                + '<strong id="this_title" class="label label-success label-tag">' + item_i.title + '</strong>'
                            + '</a>'
                        + '</span>'
                    + '</div>'
                + '';
           
            content += ''
                    + '<div id="collapse_' + idx_i + '" class="panel-collapse in">'
                        + '<div class="panel-body placeholders">'
                + '';
                
            $.each(item_i.portals, function(idx_j, item_j){
                if (item_j.img) {
                    item_img = img_path + item_j.img;
                    //console.info('item_id=' + idx_j + ', item_name=' + item_j.name + ', item_img=' + item_img);
                } else {
                    item_img = img_path + img_default;
                }
                
                content += ''
                            + '<div class="col-xs-4 col-sm-2 placeholder">'
                                + '<img src="' + item_img + '" class="img-item-list img-responsive">'
                                + '<a class="portal" target="_blank" href="' + item_j.url+ '">'
                                    + '<h5 class="text-muted">' + item_j.name + '</h5>'
                                + '</a>'
                            + '</div>'
                + '';
            });
            
            content += ''
                        + '</div>'
                    + '</div>'
                + '</div>'
                + '<!-- End of panel-->'
                + '';
                
             $("div#panel_lists").append(content);
        });
    });

}


/*
 * 用途：页面加载后的操作
 */
$(document).ready(function(){
    //页面首次加载
    var prefix = 'static/data/';            //json 数据文件
    var default_suffix = 'appid_a1';                //默认读取的 json 文件的名称
    request = location.hash.slice(1);
    suffix = request ? request : default_suffix; 
    json_file = prefix + suffix + '.json'
    //console.info('json_file1 = ' + json_file);
    load_data_from_json(json_file);
    
    
    //<a href="#appid_xxx"> 单击事件响应
    $("[href^='#appid_']").click(function(){
        suffix = $(this).attr("href").slice(1);
        json_file = prefix + suffix + '.json'
        //console.info('json_file2 = ' + json_file);
        load_data_from_json(json_file);
    });

});
