# ops
2018/11/21

### init

> 我时不时会思考，要如何简单粗暴的的描述 `互联网运维` 这份工作是干啥的？尤其是面对行业外人士的疑惑时。`技术运营`如何？可能当下议论纷纷的 `DEVOPS/SRE` 理念延伸一下变成 `development operations(研发运营) `更佳？（据我面试/工作经历中留下的印象，国内互联网公司诸如腾讯、网宿、小米、ofo等公司的部分职位已然是诸如：`高级运营工程师`，`运营开发工程师`，`SRE` 这样的头衔）


collecting #ops# related basic docs here.

基础知识库：收集整理本人工作经历中接触到的一些 ops 相关的知识点。

服务对象：互联网运维工程师，软件工程师。

**学而时习之，温故而知新**

**好记性不如烂笔头**


### Who Might Need This

* **ops**
* **dev**
* **qa**



### Commit Message Format
---

(from: [portainer](https://raw.githubusercontent.com/portainer/portainer/develop/CONTRIBUTING.md))

Each commit message should include a **type**, a **scope** and a **subject**:

```
 <type>(<scope>): <subject>
```

###### Type

Must be one of the following:

* **feat**: A new feature
* **fix**: A bug fix
* **docs**: Documentation only changes
* **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing
  semi-colons, etc)
* **refactor**: A code change that neither fixes a bug or adds a feature
* **test**: Adding missing tests
* **chore**: Changes to the build process or auxiliary tools and libraries such as documentation
  generation

##### Scope

The scope could be anything specifying place of the commit change. For example `networks`,
`containers`, `images` etc...
You can use the **area** label tag associated on the issue here (for `area/containers` use `containers` as a scope...)

##### Subject

The subject contains succinct description of the change:

* use the imperative, present tense: "change" not "changed" nor "changes"
* don't capitalize first letter
* no dot (.) at the end


### For Newcomers
---

**Notice**: no security relatied articles here, as it's not easy to talk about this. Please follow the official doc for all open source softwares.

注1：凡是本人整理的，开源产品相关的文章中，标题党写明了“最佳实践”的文章，要特别注意，本人总结的文字并未涉及安全方面的指导，请参考官方的指导教程，因为安全是一个有深度的话题，且安全是相对而言的，并不是个容易的话题。

注2：本人整理的所有知识库，基础内容占比多，因为在学习的路上，总是容易卡在某个点上，希望能对路过的你有点帮助即可，力求普及知识，而非教科书一般的按步骤12345来指导即可上生产环境，请自行总结，走出自己的路，加油。
