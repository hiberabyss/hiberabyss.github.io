---
title: 为 maupassant 主题添加文章版权信息和推荐阅读功能
date: 2018-05-06 18:14:22
toc: true
categories: Hexo
tags:
    - Hexo
---

在网上看过别人的博客主题后, 发现我现在用的 maupassant 主题缺少了两个实用的功能:
在文章末尾添加版权信息和相关文章推荐阅读.

既然缺少功能, 那就参照别人的代码添加上对应的功能呗, 这就是我为什么选择自己搭建独立博客的原因:
可以随心所欲地进行定制化.

<!--more-->

# 最终效果

下面是按照本文步骤操作完成之后的效果:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1525645916729.png" width="754"/>

其中第一部分推荐阅读是通过插件 [hexo-recommended-posts](https://github.com/huiwang/hexo-recommended-posts)
来实现的, 它不仅可以推荐你自己的博客, 还可以推荐别人的相关博客.
如果有比较多人使用这个插件的话, 不仅能帮读者快速找到感兴趣的内容, 同时也能增加自己博客的流量.

# 在文章末尾自动添加版权信息

我们先在主题的 `_config.yml` 中添加一些配置信息:

```yaml
post_copyright:
  enable: true
  author: "Hongbo Liu"
```

然后在 `layout/post.pug` 文件中添加相关代码:

```pug
    if theme.post_copyright.enable == true
      div
        ul.post-copyright
          li.post-copyright-author
            strong 本文作者：
            = theme.post_copyright.author
          li.post-copyright-link
            strong 本文链接：
            a(href='/' + page.path)= page.permalink
          li.post-copyright-license
            strong 版权声明：
            | 本博客所有文章除特别声明外，均采用 <a href="http://creativecommons.org/licenses/by-nc-sa/3.0/cn/" rel="external nofollow" target="_blank">CC BY-NC-SA 3.0 CN</a> 许可协议。转载请注明出处！
      br
```

最后在 `source/css/style.scss` 样式文件中添加对应的样式描述:

```scss
// Custom styles.
.post-copyright {
    margin: 2em 0 0;
    padding: 0.5em 1em;
    border-left: 3px solid #FF1700;
    background-color: #F9F9F9;
    list-style: none;
    li {
        margin: 8px 0;
    }
}
```

# 文章推荐功能支持

先安装 hexo-recommended-posts :

```shell
npm install hexo-recommended-posts --save
```

安装完这个 hexo 插件后直接执行 `hexo recommend` , 其实就已经可以添加推荐文章支持.
如下图所示:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1525647516111.png" width="418"/>

但这里的推荐文章是和博客正文混在一起的, 而且样式也不好看.
我们还是把它放在正文后面, 使用和版权信息类似的样式格式.

首先我们还是需要在主题的 `_config.yml` 文件中添加一些配置信息:

```yaml
recommended_posts:
  enable: true
```

然后同样也是在 `layout/post.pug` 文件中添加相关的代码:

```pug
    if theme.recommended_posts.enable == true
      div.recommended_posts
        h3() 推荐阅读
        - var post_list = recommended_posts(page, site)
        - for (var i in post_list)
            li
              a(href=post_list[i].permalink, target='_blank')= post_list[i].title
```

再在 `source/css/style.scss` 中添加样式配置:

```scss
.recommended_posts {
    padding: 0.5em 1em;
    border-left: 3px solid #6f42c1;
    background-color: #f5f0fa;
    li { margin: 5px 0; }
    a:link { color: blue; }
    a:hover { text-decoration:underline;color: red}
    a:visited { color: green; }
}
```

最后我们还需要在博客的 `_config.yml` 文件中添加插件相关的配置信息:

```yaml
recommended_posts:
  autoDisplay: false
```

现在当我们执行下列命令后便可以在博客中看到推荐文章相关的信息:

```shell
hexo recommend
hexo generate
hexo server
```

# 总结

这里的代码修改还是很简单的, 不过因为对 Pug 的语法不熟悉, 导致浪费了不少时间,
还是应该好好了解下这门 html 的模版语言的. 在后面的参考链接中我也列出了 pug 的一些学习文档.

# 参考链接

- [hexo文章末尾添加版权信息](http://stevenshi.me/2017/05/26/hexo-add-copyright/)
- [hexo-recommended-posts](https://github.com/huiwang/hexo-recommended-posts)
- [Pug - 模板引擎](https://github.com/pugjs/pug-zh-cn/blob/master/Readme_zh-cn.md)
- [Pug 官方文档](http://www.url.com)
- [pug模板语法](https://hamger.github.io/2017/04/07/pug%E6%A8%A1%E6%9D%BF%E8%AF%AD%E6%B3%95/)
