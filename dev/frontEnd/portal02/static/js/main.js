/*
 * main.js
 * pc@20170630
 */




/*
 * 用途：生成右上角菜单的数据
 * json_file： 提供 json 数据来源
 */
function load_nav_topright_from_json(json_file){
    $("ul#navbar_topright").empty();
    $.getJSON(json_file,function(result){
        //console.info(result.data);
        $.each(result.data, function(idx_i, item_i){
            var content = '';
            content = ''
                    + '<!-- navbar_topright Start-->'
                    + '<li class="dropdown">'
                        + '<a href="#" class="dropdown-toggle" data-toggle="dropdown">' + item_i.text + '<b class="caret"></b></a>'
                        + '<ul class="dropdown-menu">'

            $.each(item_i.nodes, function(idx_j, item_j){
                content += ''
                            + '<li><a id="appid" href="' + item_j.href + '">' + item_j.text + '</a></li>';
            });
            
            content += ''
                        + '</ul>'
                    + '</li>';
                
             $("ul#navbar_topright").append(content);
        });
    });

}


/*
 * 用途：生成左侧侧边栏的数据
 * json_file： 提供 json 数据来源
 */
function get_tree(json_file) {
    $.getJSON(json_file,function(result){
        $('div#tree').treeview({
            data: result.data,
            showBorder: false,
            expandIcon: 'glyphicon glyphicon-chevron-right',
            collapseIcon: 'glyphicon glyphicon-chevron-down',
            nodeIcon: 'glyphicon glyphicon-link',
            enableLinks: true
        });
    });
}


/*
 * 用途：生成右侧内容栏的数据
 * json_file： 提供 json 数据来源
 */
function load_content_from_json(json_file){
    $("div#panel_lists").empty();
    $.getJSON(json_file,function(result){
        //console.info(result.data);
        $.each(result.data, function(idx_i, item_i){
            var content = '';
            var img_path = './static/images/';
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

                                + '<a class="portal" target="_blank" href="' + item_j.url+ '">'
                                    + '<img src="' + item_img + '" class="img-item-list img-responsive">'
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
    var prefix = './static/data/';                      //json 数据文件存放目录
    var default_suffix = 'appid_a1';                    //默认读取的 json 文件的名称
    
    //加载默认内容
    request = location.hash.slice(1);
    suffix = request ? request : default_suffix; 
    json_file_default = prefix + suffix + '.json'
    //console.info('json_file_default = ' + json_file_default);
    load_content_from_json(json_file_default);

    //加载右上角菜单
    json_file_treeview = prefix + 'public_treeview.json'
    //console.info('json_file_treeview = ' + json_file_treeview);
    load_nav_topright_from_json(json_file_treeview);    

    
    //加载左侧的侧边栏 treeview
    get_tree(json_file_treeview);


    // treeview 的节点选中事件响应【js动态生成的选择器】
    $(document).on('nodeSelected', 'div#tree', function(event, data) {
        if (data.href && data.href.length > 1) {
            suffix = data.href.slice(1);
            json_file_tree_node = prefix + suffix + '.json'
            //console.info('json_file_tree_node = ' + json_file_tree_node);
            load_content_from_json(json_file_tree_node);
        }
    });
    

    //<a href="#appid_xxx"> 的单击事件响应【js动态生成的选择器】
    $(document).on('click', 'a#appid', function() {
        suffix = $(this).context.hash.slice(1);
        json_file_a_appid = prefix + suffix + '.json'
        //console.info('json_file_a_appid = ' + json_file_a_appid);
        load_content_from_json(json_file_a_appid);
    });
    
});
