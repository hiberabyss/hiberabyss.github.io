---
title: 「VimTips」 快速执行 Normal 命令
date: 2021-02-05 15:19:49
toc: true
mathjax: true
categories:
tags:
    - vim
---

在批量对一些行做一些简单修改时，使用 `normal` 命令会很方便。
例如可以通过 `%normal A,` 在文件所有行的末尾添加一个 `,` 字符。
但 `normal` 命令会频繁地触发 `InsertEnter`、`InsertLeave` 等事件，一些插件例如 `airline` 会监控这些事件来执行某些操作，
这会导致 `normal` 命令执行特别慢，处理每一行时都会有一些卡顿。

本文会介绍如何屏蔽已安装插件的影响，能够快速地执行 `normal` 命令。

<!--more-->

# 通过选项 `eventignore` 来避免触发事件

Vim 里有个 `eventignore` 选项，通过配置它能够忽略某些特定或所有的事件。下面是帮助文档里的描述：

> A list of autocommand event names, which are to be ignored.
> When set to "all" or when "all" is one of the items, all autocommand
> events are ignored, autocommands will not be executed.

有了这个选项之后就可以通过如下地步骤来让 `normal` 命令快速执行：

1. 执行前屏蔽所有事件 `set eventignore=all`
2. 执行 normal 命令 `:%noraml I"A"`
3. 恢复 eventignore 选项 `set eventignore=`

上面这几个步骤可以封装成一个命令，下面的代码就是把上面的 3 个步骤封装成命令 `Normal`：

```vim
function! s:NormalIgnoreAllEvents(args) range
  let l:cur_eventignore = &eventignore
  set eventignore=all
  execute(printf('%d,%dnormal %s', a:firstline, a:lastline, a:args))
  let &eventignore = l:cur_eventignore
endfunction

command! -nargs=1 -range Normal <line1>,<line2>call s:NormalIgnoreAllEvents('<args>')
```

把上面的代码放到 `.vimrc` 里之后就可以通过 `%Normal A,` 的方式来别面其它插件的影响，
快速执行 `normal` 命令。

上面的 `Normal` 命令定义中通过 `-range` 让它支持指定一个执行的区间，
同时在函数定义的最后加上了 `range`，这样函数就能取到 `a:firstline` 和 `a:lastline` 两个参数，
同时这个函数也只会被调用一次。
