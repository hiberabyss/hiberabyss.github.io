---
title: 「neovim」基于 neovim 终端集成 gdb
date: 2018-02-28 11:17:35
toc: true
tags:
    - neovim
    - gdb
---

相比于 IDE, 当使用 VIM 作为编辑器时, 调试会显得很麻烦.
借助于 neovim 的终端, 我们可以在 VIM 中实现类似 IDE 的编辑调试功能:
在 VIM 编辑窗口中按特定的快捷键即可执行特定的调试命令, 同时在 VIM 窗口中也能显示当前的
断电及程序执行的位置.

<!--more-->

# 演示

安装 VIM 插件 [NeovimGDB](https://github.com/hiberabyss/NeovimGdb):

```vim
Plug "https://github.com/hiberabyss/NeovimGdb"
```

然后便可实现如下的效果:

<script src="https://asciinema.org/a/dT2652AAwegDo0o0gWKsGOo1W.js" id="asciicast-dT2652AAwegDo0o0gWKsGOo1W" async></script>

其中的主要操作步骤包括:

1. 执行 GdbLocal 命令进入 GDB 模式;
2. 按快捷键 `;b` 设置断点 (再次按这个快捷键可以取消断点)
3. 按 `;r` 开始执行程序;
4. 按 `;n` 执行到下一行;
5. 按 `;p` 打印光标下的变量;
6. 按 `;gk` 退出 GDB 模式

