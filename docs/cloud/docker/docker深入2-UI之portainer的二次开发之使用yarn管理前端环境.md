# docker深入2-UI之portainer的二次开发之使用yarn管理前端环境
2018/10/18

### 问题点
1. 前端
2. 后端



前端
---
> 当前(2018-10)给前端贡献代码时，环境变成了yarn来控制依赖，如何操作？

**需求**
```
Docker
Node.js >= 6
yarn
```

**构建**
克隆代码：
```bash
$ git clone https://github.com/portainer/portainer.git
$ cd portainer

yarn解决依赖：
```

```bash
$ yarn
```


yarn构建：
```bash
$ yarn build
```


yarn启动：
```bash
$ yarn dev
```

访问： http://localhost:9000

> 提示
>
> 当有代码文件变更发生时 (app/**/*.js, assets/css/app.css or index.html)，前端页面会自动更新，此时刷新浏览器即可



**Important**

别忘了要 lint 代码：
```bash
$ yarn grunt lint
```



后端
---
> 默认是通过一个 golang 镜像来构建后端代码，如果有网络问题，将导致构建失败，最终影响前端允许，怎么处理？


假设不能解决网络问题，则去 [releases](https://github.com/portainer/portainer/releases) 下载对应版本的 `binary` 存放到 `Portainer` 代码根目录的 `dist/` 目录下，然后注释以下内容来跳过构建操作：

* build/build_in_container.sh
  ```
  (略)
  #docker run --rm -tv "$(pwd)/api:/src" -e BUILD_GOOS="$1" -e BUILD_GOARCH="$2" portainer/golang-builder:cross-platform /src/cmd/portainer

  #mv "api/cmd/portainer/$binary" dist/
  (略)
  ```

* build/download_docker_binary.sh
  ```
  #!/usr/bin/env bash
  exit 0
  (略)
  ```

然后再去执行前端操作即可。


*不足*
portainer 理应提供 golang 代码的依赖解决方案(dep, go.mod等)来保证构建环境的一致性(我尝试补充，但不清楚依赖的版本，未能解决)。


ZYXW、参考
---
1、doc
https://portainer.readthedocs.io/en/stable/contribute.html
