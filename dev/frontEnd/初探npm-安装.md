# 初探npm-安装
2018/12/24


注： npm 包含在 nodejs 中

### install nodejs on mac

访问：
https://nodejs.org/zh-cn/

下载稳定版本到 mac 下安装即可。

为了加速安装过程，设置仓库
```bash
npm config set registry https://registry.npm.taobao.org --global

```

或者：安装 cnpm 来替代 npm
```bash
npm install -g cnpm --registry=https://registry.npm.taobao.org

```


### 清理cache
```bash
npm start --reset-cache

```



### ZYXW、参考
1. [taobao-npm](https://npm.taobao.org/)
