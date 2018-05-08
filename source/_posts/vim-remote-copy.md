---
title: 「VIM」 从远程机器复制文件内容到本机剪贴板
date: 2017-11-30 12:35:19
toc: true
categories: Vim
tags:
    - Vim
---

通过 ssh 登录到远程机器后，想要复制远程机器的文件内容是一件很麻烦的事情。
通过拖动来复制对于多行的内容很难实现精确定位，还有可能会遇到换行符的问题。利用
[clipper](https://github.com/wincent/clipper) 命令可以很方便地复制远程机器的内容到本机剪贴板中。

<!--more-->

## 安装与启动

macOS 系统可以通过 `brew install clipper` 安装。安装完成后通过 `brew services start clipper` 启动。
通过以下命令检查 clipper 是不是正常启动：

```txt
➜  blog git:(hexo) ✗ ps -ef | grep clipper
  502   463     1   0  3:07PM ??         0:00.09 /usr/local/opt/clipper/bin/clipper
```

## 简单演示

当确认 clipper 启动成功后，通过下面的命令连接到远程机器：

```shell
ssh -R 8377:localhost:8377 192.168.0.32
```

确认远程机器上安装有 `nc` （对于 CentOS 机器可以通过 `sudo yum install -y nmap-ncat` 来安装），
执行下面的命令：

```shell
echo hello,world | nc localhost 8377
```

现在 “hello,world” 字符转已经成功复制到本机的剪贴板了。可以切换到浏览器地址栏粘贴查看结果。

每次连接远程机器都需要加上 `-R 8377:localhost:8377` 参数显得有些冗余，我们可以通过修改 `~/.ssh/config`
文件来实现连接远程主机时默认加上这个参数，只需把下面这行添加到文件 `~/.ssh/config` 里：

```sshconfig
RemoteForward 8377 localhost:8377
```

## 在远程主机的 VIM 里复制内容

我们可以利用 `:[range]w[rite] [++opt] !{cmd}` 来实现文件内容的复制：

- 复制当前行：在 VIM 中执行 `:.w !nc localhost 8377`
- 复制选中的行：选中要复制的行后，执行 `:'<,'>w !nc localhost 8377` ( 进入命令行模式后 VIM 会自动帮忙填充 `'<,'>`)
- 复制整个文件：在 VIM 中执行 `:%w !nc localhost 8377`
- 复制 VIM 默认 register 的内容：在 VIM 中执行 `:call system('nc localhost 8377', @")`

### 通过 VIM 插件 vim-clipper

安装了 [vim-clipper](https://github.com/wincent/vim-clipper) 插件后：

```vim
Plug 'https://github.com/wincent/vim-clipper'
```

可以直接通过命令 `:Clip` 来复制 VIM 默认 register 的内容。
