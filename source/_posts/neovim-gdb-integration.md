---
title: 「neovim」基于 neovim 终端集成 gdb
date: 2018-02-28 11:17:35
categories: vim
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
# Requirement

* Neovim
* gdb (C, C++);
* delve (golang); 可通过 `go get -u github.com/derekparker/delve/cmd/dlv` 安装

# [演示](https://asciinema.org/a/dT2652AAwegDo0o0gWKsGOo1W)

安装 VIM 插件 [NeovimGDB][NeovimGdb]

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

# 使用

* 对于 C, C++ 类型文件, 可以通过 `GdbLocal` 启动调试窗口 (或通过默认按键映射 `,rd`); 
* 对于 go 类型文件, 可以通过 `GoDebug` 启动调试窗口;
* 可以调用命令 `GdbDebugStop` 来停止调试 (默认按键映射为 `;gk`);

我们可以直接在调试窗口中输入调试命令, 也可以通过下列按键映射从代码窗口往调试窗口发送命令:

* `;r` 发送 r 
* `;c` 发送 c
* `;b` 发送 b
* `;n` 发送 n
* `;p` 发送 p word_under_cursor
* `;u` 发送 u

[NeovimGdb]: https://github.com/hiberabyss/NeovimGdb
