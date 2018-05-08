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
通过 [SmartIM](https://github.com/ybian/smartim.git) 插件可以很好的解决这个问题。

<!--more-->

## SmartIM 是怎么解决这个问题的

SmartIM 会检查 VIM 的 mode，如果是 Normal 模式时会自动切换成英文输入法；同时，
它也会记录下 Insert 模式下的输入法状态，当进入 Insert 模式后悔自动恢复之前的输入法状态。
SmartIM 目前只能在 macOS 系统下工作。

## 安装到 VIM

我使用 [vim-plug](https://github.com/junegunn/vim-plug) 来管理 VIM 插件，在 `.vimrc` 里加入下面这行：

```vim
Plug 'https://github.com/ybian/smartim.git'
```

并执行命令 `:PlugInstall smartim` 即可成功安装。

## 按需启动

SmartIM 和 VIM 插件 [VisIncr](https://github.com/vim-scripts/VisIncr.git) 有冲突，
它们俩同时启动是会导致 VisIncr 的命令执行特别慢。于是我就想只有在需要 SmartIM 的时候才启动它。

SmartIM 可以通过一个选项关闭，我们就可以默认关闭它，然后自定义命令来启用或禁止它的使用：

```vim
let g:smartim_disable = 1
command! -nargs=0 SmartIM let g:smartim_disable = 0
command! -nargs=0 SmartIMdisable let g:smartim_disable = 1
```

在某些项目里，我们可能希望能默认启动 SmartIM ，比如 blog 目录。这时我们可以利用插件
[ProjectConfig](https://github.com/hiberabyss/ProjectConfig) 来执行 per project 的 VIM 配置，
这个插件需要项目文件通过 git 进行管理，它会自动找到项目根目录，在 `.git` 目录里加入 VIM 配置文件，
当在这个项目的任意目录启动 VIM 时会自动加载之前保存的配置文件。

为了能在 blog 项目里默认启动 SmartIM，我们只需执行 `:ProjectConfig` 命令，然后输入下面的内容即可：

```vim
SmartIM
```

