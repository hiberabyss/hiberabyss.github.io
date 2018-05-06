---
title: "Hexo 源文件备份"
date: 2017-03-13 01:00:26
toc: true
categories: Hexo
tags:
    - hexo
---

在执行完 `hexo generate -d` 命令后会把生成的 html 文件上传到 github 上，我们还需要一种方法来备份源 markdown 文件及对应的 hexo 配置文件，
这样才能比较方便地在别的地方来生成对应的博客网站。对于这个备份机制会有以下几个需求：

<!--more-->

## 使用不同分支来分别保存博客源代码及生成的博客网站

### 使用 master 分支来保存生成的博客网站

因为 Github Page 要求使用 master 分支，我们便用 master 分支来保存生成的博客网站。
在装完 `hexo-deployer-git` 插件后，我们可以在 `_config.yml` 文件里添加如下的配置来指定博客的部署位置：

```yaml
deploy:
  type: git
  repo: git@github.com:your-github-name/your-github-name.github.io.git
  branch: master
```

然后就可以使用 `hexo generate -d` 来基于你写的 markdown 文件来生成对应的博客网站，并部署到 github 上。

### 使用 hexo 分支来保存博客源文件

在你的 Github Page Repository 里新建一个 hexo 分支，并把它设置成默认分支，这样以后打开这个 repository 的时候默认展示的就是这个分支里的内容。
需要把以下文件保存到 hexo 分支里：

```text
_config.yml
package.json
scaffolds
source
themes
```

其中 package.json 文件是为了在 clone 了博客源代码库之后可以很方便地通过 `npm install` 就能方便地生成 hexo 博客系统所依赖的所有包。
为了能在 package.json 里记录所有的包信息，需要在安装包时添加 `--save` 参数，例如：`npm install hexo-deployer-git --save`。

这篇[博客](http://www.dxjia.cn/2016/01/27/hexo-write-everywhere/)有详细介绍如何通过不同分支来保存博客源文件及对应生成的博客网站文件。

## 同时保存生成的网站文件及对应的源代码

 `hexo-cli` 工具里有提供自动部署网站到 github 的功能，但并没有提供保存对应的源代码的机制，我们可以利用 git hook 来实现在部署网站时也自动 push 源代码
改动到 github。

`hexo-cli`  是把对应的网站代码保存到 `/path/to/blog/.deploy_git` 这个 git repository 里，我们可以在这个 git 库里添加如下的 `pre-push` hook 来实现
部署网站时自动保存源代码到 hexo 分支：

```shell
cd ..
git add .
git commit -m 'Regular save'
git push origin
```

可以通过脚本的方式来自动地添加这个 `pre-hook`，具体怎么实现可以参考我写的这个[脚本](https://github.com/hiberabyss/hiberabyss.github.io/blob/hexo/blog)。
