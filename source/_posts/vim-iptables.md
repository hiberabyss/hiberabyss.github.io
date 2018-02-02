---
title: 直接在 vim 里编辑 iptables 规则 
date: 2018-02-02 13:53:52
toc: true
tags:
    - VIM
    - iptables
---

这几天为了了解 K8S 的工作原理, 需要频繁地更改 iptables ,
直接通过 `iptables -t nat -A ...` 去添加规则, 或者通过 `iptables -t nat -D ...`
去删除规则显得很繁琐. 其实我们可以利用 vim 的 autocmd 命令来直接编辑 iptables 并保存.

<!--more-->

# 原理

我们主要是通过 `sudo iptables-save` 来导出当前的 iptable 规则, 基于现有的规则做了一些修改之后,
可以通过 `sudo iptables-restore` 来导入我们修改之后的规则. 同时, 基于 vim 的 autocmd, 
我们可以在用 `:e` 重载 buffer 时基于 `iptables-save` 来读取当前的 iptables 规则, 在用 `:w`
保存 buffer 时基于 `iptables-restore` 来将我们的修改保存到 iptable .

# 读取当前 iptalbe 规则

首先, 我们将当前 iptable 规则导出到文件, 并用 vim 打开:

```sh
sudo iptables-save > iptables.txt
vim iptables.txt
```

再执行下面的 vim autocmd 命令:

```vim
autocmd! bufread <buffer> %d | 0r !sudo iptables-save
```

这样, 当我们执行 `:e` 时就回自动获取当前系统中的 iptable 规则.

命令中的 `<buffer>` 表明这条 autocmd 只在当前 buffer 中生效.

# 保存修改后的 iptable 规则

执行下面的 vim 命令:

```vim
autocmd! bufwritepost <buffer> %w !sudo iptables-restore
```

现在当我们在 vim 中执行 `:w` 来保存内容时, 当前 buffer 里的规则也会自动保存到 iptalbe 里.
