---
title: 给 Hexo 博客集成 gitalk 评论系统
date: 2018-03-19 14:56:12
toc: true
categories: Hexo
tags:
    - Hexo
---

之前博客用的是 [Valine](https://valine.js.org/#/),
选择它的原因是可以匿名评论. Valine 的缺点是没有办法对新的评论发邮件提醒, 虽然官方文档说是可以的,
但一直没能按文档配置成功.

Gitalk 是一款基于 github issue 的评论系统, 它的缺点是没办法匿名评论,
但鉴于我的博客是技术博客, 大部分读者应该都是有 github 账号的, 这个缺点还是可以忍受的.

<!--more-->

# 如何集成 Gitalk

[Gitalk](https://github.com/gitalk/gitalk) 官网有详细的安装介绍, [这儿](https://github.com/tufu9441/maupassant-hexo/blob/master/layout/_partial/comments.pug)
是 maupassant 主题的一个集成示例.

[这儿](https://github.com/hiberabyss/maupassant-hexo/blob/7b9dbaf84c489e92bfed0a3275b5b7264285cfe5/_config.yml#L11)
是我的 maupassant 主题中 Gitalk 的配置示例.

# 使用 md5 解决 label 过长的问题

Gitalk 中每篇博客都是和一个 issue 对应的, 博客的评论内容就是存储在对应的 issue 中:

* 每篇博客都会有一个 id, 这个 id 是以 issue label 的形式存储的
* id 默认是博客的链接地址
* Github 对 label 的长度有限制, 最多只能是 50 个字符

当博客的标题比较长时, 很容易就会超过 50 个字符的限制, 这时就会出现 "Error: Validation Failed."
这样的错误.

为了解决这个问题, 我们可以使用博客链接地址的 md5 值作为博客的 id. 这需要我们修改 gitalk 的集成脚本:

```pug
    script(type='text/javascript' src='//cdn.bootcss.com/blueimp-md5/2.10.0/js/md5.js')

    ...
    id: md5(window.location.pathname),
```

[这儿](https://github.com/hiberabyss/maupassant-hexo/blob/master/layout/_partial/comments.pug#L74)
是完整的示例代码.

这里我们使用 `window.location.pathname` 作为计算 md5 的输入, 它不包括链接中的 host 部分,
这样当我们的博客存在不同的镜像时, 可以让不同主机上的相同博客共享同一套评论.

# 初始化所有博客的评论系统

[这篇博客][init]详细介绍了如何对之前的博客初始化评论系统, 这里我们只介绍如何通过 sitemap 的方法来进行初始化.

## 环境准备

在开始之前需要我们准备好一下环境:

* 生成了博客的 sitemap.xml 文件
* 在 [Personal Access Tokens](https://github.com/settings/tokens) 界面中创建一个新的 token, 需要选中所有 repo 的权限
* 安装依赖的 gem 包: `sudo gem install faraday activesupport sitemap-parser`

上面的环境准备好了之后, 把对应的信息填到下面的 ruby 脚本并执行即可:

```ruby
username = "hiberabyss" # GitHub 用户名
token = "your-token"  # GitHub Token
repo_name = "BlogComments" # 存放 issues
sitemap_url = "https://hiberabyss.github.io/sitemap.xml" # sitemap
kind = "Gitalk" # "Gitalk" or "gitment"

require 'open-uri'
require 'faraday'
require 'active_support'
require 'active_support/core_ext'
require 'sitemap-parser'
require 'uri'
require 'digest/md5'

sitemap = SitemapParser.new sitemap_url
urls = sitemap.to_a

conn = Faraday.new(:url => "https://api.github.com/repos/#{username}/#{repo_name}/issues") do |conn|
  conn.basic_auth(username, token)
  conn.adapter  Faraday.default_adapter
end

urls.each_with_index do |url, index|
  uri = URI::parse(url)
  url_md5 = Digest::MD5.hexdigest(uri.path)

  title = open(url).read.scan(/<title>(.*?)<\/title>/).first.first.force_encoding('UTF-8')
  response = conn.post do |req|
    req.body = { body: url, labels: [kind, url_md5], title: title }.to_json
  end
  puts response.body
  sleep 15 if index % 20 == 0
end
```

在这个脚本中我们也是用博客链接的 md5 值作为 id 的.

# References

- [自动初始化 Gitalk 和 Gitment 评论][init]

[init]: https://draveness.me/git-comments-initialize
