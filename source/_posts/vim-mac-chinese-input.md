---
title: 【Vim】macOS 系统下 Vim 编辑中文 tips
date: 2017-11-14 00:01:05
toc: true
categories: Vim
tags:
    - Vim
    - macOS
---

因为 VIM 里存在多个 mode ，使得编辑中文变得很痛苦。在 Insert mode 下需要使用中文输入法，
但当切换回 Normal 模式后又需要使用英文输入法。在 VIM 里切换 mode 是很经常的事儿，
在需要输入中文时，每次的 mode 切换都需要进行输入法的切换，很麻烦。
通过 [fcitx-vim-osx](https://github.com/CodeFalling/fcitx-vim-osx) 插件可以很好的解决这个问题。

<!--more-->

## fcitx-vim-osx 是怎么解决这个问题的

fcitx-vim-osx 会检查 VIM 的 mode，如果是 Normal 模式时会自动切换成英文输入法；同时，
它也会记录下 Insert 模式下的输入法状态，当进入 Insert 模式后悔自动恢复之前的输入法状态。
fcitx-vim-osx 目前只能在 macOS 系统下工作。

## 安装

在安装之前需要先按照[这里](https://github.com/CodeFalling/fcitx-remote-for-osx)的教程配置安装对应的命令.

我使用 [vim-plug](https://github.com/junegunn/vim-plug) 来管理 VIM 插件，在 `.vimrc` 里加入下面这行:

```vim
Plug 'https://github.com/CodeFalling/fcitx-vim-osx'
```

并执行命令 `:PlugInstall fcitx-vim-osx` 即可成功安装。
