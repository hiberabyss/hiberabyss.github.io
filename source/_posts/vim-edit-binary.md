---
title: 如何使用 Vim 编辑二进制文件
date: 2020-04-26 14:04:52
toc: true
categories:
tags:
    - vim
    - binary
---

前段时间参加公司内部的一个技术比赛：实现一个打印自己 MD5 值的最小 elf64 格式二进制文件。
在这个过程中需要对二进制文件的某些字节进行修改、删除等编辑操作，本文介绍如果通过 Vim 来编辑二进制文件。

<!--more-->


# 基于 xxd 命令来实现

先设定 buffer 和文件的编码格式为 utf-8 ：

```vim
set encoding=utf-8
set fileencoding=utf-8
```

打开二进制文件，设定 binary 模式 `set binary`， 在 Vim 里执行 `%!xxd -g1` 即可用类似下面的界面编辑二进制文件字节：

![](https://raw.githubusercontent.com/hiberabyss/pictures/master/20200426214430.png)

再执行 `:%!xxd -r` 转换成原始文件的格式。

# 使用 Vim 插件 Vinarise

[Vinarise](https://github.com/Shougo/vinarise.vim) 是一个支持二进制编辑的插件，安装之后执行 `Vinarise` 即可按二进制的方式编辑文件。

Vinarise 提供了很多方便的功能，例如移动等操作都是以字节为单位的，`/` 可以直接按二进制序列进行搜索，
`g/` 则可以俺字符串进行搜索。

Vinarise 的不足之处是对删除的操作支持不够，例如不支持 `d` 这个操作，虽然可以通过 `x` 删除一整个字节，但是不支持 `undo` 操作。

