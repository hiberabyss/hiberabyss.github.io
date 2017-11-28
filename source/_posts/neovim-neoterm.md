---
title: 【VIM】neovim 下的 neoterm 插件的一些改进
date: 2017-11-15 23:52:32
toc: true
tags:
    - VIM
    - neovim
---

Neovim 原生支持 terminal 功能，在编辑文件的同时可以新开一个 terminal 窗口，
在其中执行命令。例如我可以在写博客的同时开启一个 terminal 窗口，在其中执行 `hexo s`，
这样就可以实时预览博客：

NOTE: 最新版本的 Neoterm 插件已经原生支持 `Tnext` 和 `Tprevious` 命令。

<!--more-->

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1510762631758.png" width="570"/>

## Neoterm

[Neoterm](https://github.com/kassio/neoterm) 是 neovim 下的一款 terminal 管理插件，
通过它可以很方便地：

- 开启新的 terminal 窗口：`Tnew`
- 给 terminal 窗口发送命令：`T python`

## 提高 neoterm 的多 terminal 窗口管理能力

当通过 neoterm 开启多个 terminal 窗口之后，对这些窗口的管理就会变得很困难。
为了能够高效地管理多个 terminal 窗口，需要能在 terminal 窗口里快速地实现下面两个功能：

- 快速跳转到上一个或下一个 terminal 窗口；
- 快速打开一个显示当前所有 terminal 的 list。

### terminal 窗口之间的快速跳转

对于这个功能我们可以利用 vim 的 `bnext` 和 `bprevious` 来实现，通过他们来遍历到上一个或下一个
terminal 窗口：

```vim
function! PreviousTerminal()
    :bprevious
    while &buftype != "terminal"
        :bprevious
    endw
endfunction

function! NextTerminal()
    :bnext
    while &buftype != "terminal"
        :bnext
    endw
endfunction

tnoremap <silent> <A-[> <c-\><c-n>:call PreviousTerminal()<cr>
tnoremap <silent> <A-]> <c-\><c-n>:call NextTerminal()<cr>
```

上面的代码里增加了两个 map ：

- 跳转到上一个 terminal 窗口：`<A-[>`
- 跳转到下一个 terminal 窗口：`<A-]>`

这样在 terminal 窗口里按对应的按键就可以跳转到上一个或者下一个 terminal 窗口。

### 快速打开当前所有 terminal 窗口的 list

当打开所有 terminal 的窗口之后，我们便可以快速地选择要切换的 terminal 窗口。

这个功能是通过 vim 的 [Unite](https://github.com/Shougo/unite.vim) 插件来实现的。
在安装完这个插件之后执行命令 `Unite buffer:t` 即可打开所有 terminal 的 list。
我们添加如下的 map ，即可实现按 `<A-o>` 来打开这个 list：

```vim
tnoremap <A-o> <c-\><c-n>:Unite -no-start-insert buffer:t<cr>
```
