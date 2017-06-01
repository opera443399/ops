//main.js


function load_data_from_json(json_file){
    $("div#panel_lists").empty();
    $.getJSON(json_file,function(result){
        $.each(result, function(idx_i, item_i){
            var content = '';
            content = ''
                + '<!-- panel Start-->'
                + '<div class="panel" id="links_online">'
                    + '<div class="panel-heading">'
                        + '<span class="panel-title">'
                            + '<a class="accordion-toggle" data-toggle="collapse" data-parent="#links_online" href="#collapse_' + item_i.idx_i + '">'
                                + '<strong id="this_title" class="label label-success label-tag">' + item_i.title + '</strong>'
                            + '</a>'
                        + '</span>'
                    + '</div>'
                + '';
           
            content += ''
                    + '<div id="collapse_' + item_i.idx_i + '" class="panel-collapse in">'
                        + '<div class="panel-body placeholders">'
                + '';
                
            $.each(item_i.portals, function(idx_j, item_j){
                content += ''
                            + '<div class="col-xs-4 col-sm-2 placeholder">'
                                + '<img src="data:image/gif;base64,R0lGODlhAQABAIAAAHd3dwAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==" class="img-item-list img-responsive" alt="Generic placeholder thumbnail">'
                                + '<a class="portal" target="_blank" href="' + item_j.url+ '">'
                                    + '<h4>' + item_j.name + '</h4>'
                                + '</a>'
                                + '<span class="text-muted">' + item_j.desc + '</span>'
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

 
$(document).ready(function(){
    $("[id^='li_opt_']").click(function(){
        suffix = $(this).attr("id");
        json_file = 'static/data/' + suffix + '.json'
        console.info('json_file = ' + json_file);
        load_data_from_json(json_file);
        
    });
    $("li#li_opt_a1").click();
});
