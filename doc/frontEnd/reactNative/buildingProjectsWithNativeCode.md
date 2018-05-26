# Building Projects With Native Code
2018/5/26


> 前言：使用 React Native 来开发 ios 项目，极大的降低了开发门槛

### 依赖
- Node
- Watchman (Facebook 提供的工具，用于监听文件系统的变化，可提高性能)
- React Native command line interface
- Xcode

##### Node, Watchman
```bash
brew install node
brew install watchman
```


##### The React Native CLI
```bash
npm install -g react-native-cli
```


##### Xcode
from mac appstore

##### 初始化项目
```bash
react-native init AwesomeProject
```

### 运行
```bash
cd AwesomeProject
react-native run-ios
```


### 异常: CFBundleIdentifier

when running react-native run-ios:

```
Print: Entry, ":CFBundleIdentifier", Does Not Exist
```

change to your react-native directory (which is probably something like `.../MyProject/node_modules/react-native`) and run this:
```bash
test -f scripts/ios-install-third-party.sh && curl -L https://git.io/vd3np | bash || echo must cd to react-native directory first

```


### 在真机上运行
项目中，进入 ios 目录，可以打开 Xcode 项目，剩下的和常规方式一样


### 编辑 App.js 的内容
更新后的内容即时生效



### ZYXW、参考
1. [Getting Started](https://facebook.github.io/react-native/docs/getting-started.html)
2. [Running On Device](https://facebook.github.io/react-native/docs/running-on-device.html)
3. [#14423](https://github.com/facebook/react-native/issues/14423)
