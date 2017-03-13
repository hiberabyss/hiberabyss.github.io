---
title: "Hexo 入门教程"
date: 2017-03-13 21:41:42
tags: Hexo
---

晚上把搭好的博客发给了我的 Best Gay Friend 看，本来只是想赚一下浏览量，但基友说也想搭一个类似的博客系统。
寻思着可以写一篇利用 Github Pages 搭建 Hexo 博客系统的入门教程，既可以增加一篇“凑字数”的博客，又可以急基友之所急。

<!-- toc -->

<!--more-->

## Hexo 的安装及使用

Hexo 的安装很简单，只用一条命令即可搞定：

```shell
npm install hexo-cli -g
```

安装完之后就可以用下面的命令来初始化一个博客：

```shell
hexo init blog
cd blog
```

然后用 `hexo server -o` 在本地打开对应的博客网站。
这些在 [Hexo 官网](https://github.com/hexojs/hexo#quick-start)上都有介绍。 

## 自定义Hexo

可以通过编辑 `blog/_config.yml` 文件来对你的博客网站进行配置，例如：

```yaml
title: 始于珞尘
subtitle:
description:
author: Hongbo Liu
language: zh-CN
```

也可以修改博客的主题：

```yaml
theme: maupassant-hexo
```

主题 `maupassant` 的具体安装方法可以参考它的 [ 官方文档](https://github.com/tufu9441/maupassant-hexo )。

## 部署 Hexo 博客到 Github Pages

要使用 Github Pages 首先需要你建一个名称为 `your-github-id.github.io` 的 repository，同时需要在 repository 的设置里开启 Github Pages 功能。

然后在 `blog` 目录里安装 hexo deploy 插件：

```shell
npm install hexo-deployer-git --save
```

在 `_config.yml` 文件里添加如下的配置：

```
deploy:
  type: git
  repo: git@github.com:your-github-id/your-github-id.github.io.git
  branch: master
```

最后执行 `hexo generate -d`，大功告成！打开 http://your-github-id.github.io 就可以访问你的博客网站了！
