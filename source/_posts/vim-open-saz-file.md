---
title: 使用 Vim 查看 Fiddler 生成的 saz 格式 session 包
date: 2020-05-06 14:32:05
toc: true
categories:
tags:
    - Fiddler
    - Vim
---

Fiddler 是 Windows 下很流行的 Http 抓包工具，它可以把抓到的 Http 请求保存为 saz 格式。
在工作中调试后台服务时，同事经常会发过来一个 saz 格式的文件，但我是用的 macOS 系统，
而 Fiddler 没有 macOS 的版本，就没法直接查看 saz 格式文件。

后来通过 Google 发现 Fiddler 其实是一个 zip 包，Http 的请求和回包都保存在特定的文件里：

* `sessionid#_c.txt` 客户端请求
* `sessionid#_s.txt` 服务端回包

而最新版本的 Vim 是可以直接识别 zip 包并打开对应的文件的，这样我们就可以直接用 Vim 查看 saz 格式的文件了。
先在 vimrc 里加上如下的配置：

```vim
autocmd BufReadCmd *.saz call zip#Browse(expand("<amatch>"))
```

然后就可以直接用 Vim 打开 saz 文件了：

![](/img/posts/0f6a442b6a5d380493489cec0ff34d15-1588749137.jpg)

如果想要可以直接双击打开 saz 文件，可以安装 GUI 版本的 [VimR](https://github.com/qvacua/vimr)。

<!--more-->

