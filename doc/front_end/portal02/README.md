README
======
pc.peng@20170602

1）原理简述
-------------------

    a. 页面请求：http://m.test.com/#appid_b1
    
    b. js解析：获取 url 后面的 hash 值： #appid_b1 -> appid_b1
    
    c. 读取对于的 json 数据文件： appid_b1.json
    
    d. js生成 html code ：页面右侧内容

    

2）静态页面代码简述
-------------------

    a. 首页
    
        http://m.test.com/index.html
        代码中有注释，请参考操作。
        【重点】新增项目的操作：增加导航菜单，链接。

        
    b. js
    
        js的根目录：/static/data/
        控制数据的加载：
        http://m.test.com/static/js/main.js

        提供 json 格式的数据给 js 来加载：

        
    c. json
    
        json数据文件的根目录：/static/data/

        请求：http://m.test.com/
        默认加载数据：http://m.test.com/static/data/appid_a1.json

        【重点】新增项目的操作：增加一个对应的 json 文件。

        json 数据中 img 字段对应的图片根目录：/static/images
        默认值：
        http://m.test.com/static/images/default.svg

