README
======
pc.peng@20170602

1）原理简述
-------------------

    a. 页面请求：http://m.test.com/#appid_b1
    
    b. js解析：获取 url 后面的 hash 值： #appid_b1 -> appid_b1
    
    c. 读取对应的 json 数据文件： appid_b1.json
    
    d. js生成 html code ：页面右侧内容

    

2）静态页面代码简述
-------------------

    a. 首页
    
        用途：分类列出链接。
        http://m.test.com/index.html
        代码中有注释，请参考操作。
        
        【重点】新增项目的操作：增加导航菜单，链接。

        
    b. js
    
        用途：控制数据的加载
        http://m.test.com/static/js/main.js

        
    c. json
    
        json数据文件的根目录：/static/data/
        
        提供 json 格式的数据给 js 来加载，示例：
        ->请求：http://m.test.com/
        ->默认加载数据：http://m.test.com/static/data/appid_a1.json

        【重点】新增项目的操作：增加一个对应的 json 文件。
        数据示例：
            {
                "title": "分类标题",
                "portals": [
                    {
                        "url": "超链接",
                        "img": "图片名称",
                        "name": "描述"
                    },
                    {
                        "url": "#",
                        "img": "",
                        "name": "portal"
                    },
                    {
                        "url": "#",
                        "img": "",
                        "name": "portal"
                    }
                ]
            }

    d. image
    
        图标文件的根目录：/static/images
        字段定义：json 数据中 img 字段；
        js中的默认值： default.svg

