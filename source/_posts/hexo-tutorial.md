---
title: "Hexo 入门教程"
date: 2017-03-13 21:41:42
toc: true
tags: Hexo
---

晚上把搭好的博客发给了我的 Best Gay Friend 看，本来只是想赚一下浏览量，但基友说也想搭一个类似的博客系统。
寻思着可以写一篇利用 Github Pages 搭建 Hexo 博客系统的入门教程，既可以增加一篇“凑字数”的博客，又可以急基友之所急。

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

### 自定义 maupassant 主题

- 启用博客阅读数统计：`busuanzi: true`
- 启用对应的 Comment：gitment、valine

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

### 强制开启 https

我们可以在 Github Pages 库里的设置中开启强制 https 功能, 这样当用户访问 http 的网页时
会自动重定向到 https 页面.

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1521450041622.png" width="491"/>

## 搜索引擎检索

为了让博客的内容能被百度和 Google 检索，首先需要生成对应的 sitemap：

```shell
npm install hexo-generator-sitemap --save
npm install hexo-generator-baidu-sitemap --save
```

分别在 [百度站长工具](http://zhanzhang.baidu.com/site/index) 和 [Google 站长工具](https://www.google.com/webmasters/tools/home?hl=zh-CN)
里对你的博客站点进行验证。

选择`文件验证`的方式进行验证，把下载的文件放在 `source` 目录下，并对文件内容进行编辑，在文件首部加入如下内容：

```yaml
---
layout: false
sitemap: false
---
```

这样就可以防止 Hexo 在生成博客网站时在验证文件里添加额外的内容，导致验证失败。

也可以在博客的配置文件里加入如下的配置来防止这些文件被渲染：

```yaml
skip_render:
  - baidu_verify*.html
  - google*.html
```

具体的匹配规则可以参考这个 [comment](https://github.com/hexojs/hexo/issues/1146#issuecomment-88380140 ) 

当博客站点验证成功后便可以选择用 sitemap 的方式自动提交链接。对于百度，在站长平台工具里选择 “网页抓取-->链接提交-->自动提交-->sitemap”，
如下图所示：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1489936271715.png" width="560"/>

对于 Google 择选择 “抓取-->站点地图-->添加站点地图”，如下图所示：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1489936644191.png" width="379"/>

当做完所有这些操作之后可以通过 `site:your-blog-site` 这个搜索来验证你的博客有没有被百度和 Google 收录。
一般需要几天的时间才能保证你的博客被搜索引擎检索到。

## 使用七牛作为图床

注册 [七牛账户](https://portal.qiniu.com/signup?code=3liikw6nls3ma) 并创建一个新的 bucket（选择华东区，否则下面提到的插件无法正常使用），
利用插件 [markdown-img-upload](https://github.com/tiann/markdown-img-upload) 可以很方便地上传图片到七牛并插入图片引用到 Markdown 文件。

