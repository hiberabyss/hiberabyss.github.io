---
title: 给 Vim 插件添加上异步调用的功能
date: 2018-05-03 12:04:55
toc: true
categories: Vim
tags:
    - vim
---

一些 Vim 插件可能因为计算密集或者是访问网络资源导致命令调用特别慢,
进而导致 Vim 的操作界面被 hang 住, 时不时地 hang 一下还是很影响流畅度和编码心情的 ):

还好在 neovim/vim8 中添加了对异步调用的支持, 我们可以利用 job 机制让耗时的操作在后台执行,
然后通过 callback 机制把处理结束后的结果输出. 加上异步操作后, 各种操作都如丝般润滑,
再也不用担心卡顿了 (:

下面我就以插件 [vim-youdao-translater](https://github.com/ianva/vim-youdao-translater)
为例来介绍如何给插件添加上异步调用的功能.

<!--more-->

# vim-youdao-translater 介绍

这个插件是可以在 Vim 中调用有道词典在线版来翻译英文单词, [官方 repo 库](https://github.com/ianva/vim-youdao-translater/tree/dev-async)
中有详细的使用介绍.

但这个插件最开始不是异步调用方式, 因为需要访问有道的网络 api , 经常会在翻译的时候会出现卡顿的情况.
我便提交了 Pull Request , 在 neovim/vim8 里把翻译过程变成了异步调用.
可以通过 [vim-plug](https://hiberabyss.github.io/2018/03/21/vim-plug-introduction/) 的方式安装异步调用的版本:

```vim
Plug 'https://github.com/ianva/vim-youdao-translater.git', {'branch': 'dev-async'}
```

安装完成后我们便可以通过 `:Ydc` 翻译光标所在位置的单词了.

# 如何添加异步调用

我添加的这个异步调用是通过 neovim/vim8 的 job 机制来实现的,
它的功能和 `system` 函数类似, 用来执行外部程序, 但不同于 `system` 调用,
使用 job 执行程序的时候不会等待程序结束时再返回, 而是直接返回,
同时可以在启动 job 的时候增加回调函数来处理外部程序执行的结果.

启动 job 的函数为 `jobstart` (neovim) 或 `job_start` (vim8),
可以通过 `:help jobstart(` 或 `:help job_start(` 来查看它们的详细使用文档.

具体到 youdao-translater 这个插件, 我们需要通过 jobstart 等来执行一个 python 脚本以执行翻译的操作.
先上代码吧:

```vim
let s:translator_file = expand('<sfile>:p:h') . "/../youdao.py"
let s:translator = {'stdout_buffered': v:true, 'stderr_buffered': v:true}

function! s:translator.on_stdout(jobid, data, event)
    if !empty(a:data) | echo join(a:data) | endif
endfunction
let s:translator.on_stderr = function(s:translator.on_stdout)

function! s:translator.start(lines)
    let python_cmd = ydt#GetAvailablePythonCmd()
    if empty(python_cmd)
        echoerr "[YouDaoTranslator] [Error]: Python package neeeds to be installed!"
        return -1
    endif

    let cmd = printf("%s %s %s", python_cmd, s:translator_file, a:lines)
    if exists('*jobstart')
        return jobstart(cmd, self)
    elseif exists('*job_start')
        return job_start(cmd, {'out_cb': "ydt#VimOutCallback"})
    else
        echo system(cmd)
    endif
endfunction
```

这里调用 `jobstart` 的时候是用面向对象的方式来写的, `s:translator.on_stdout` 是对 stdout 内容的回调函数,
可以看出我们只是简单地调用 `echo` 把 python 脚本输出的翻译结果打印了出来.

调用 `job_start` 时的工作机制类似, 只不过是使用了不同的回调函数, 因为 neovim he vim8 的回调函数的参数是不一样的.
函数 `ydt#VimOutCallback` 的实现如下所示:

```vim
function! ydt#VimOutCallback(chan, msg)
    echo a:msg
endfunction
```

这里函数之所以起了这样一个名字, 是因为用到了 vim 的 autoload 机制, 上面的函数是保存在文件 `autoload/ydt.vim` 中的,
所以函数名需要以 `ydt#` 开头.

Vim 的 autoload 机制可以提高 Vim 的启动速度, 因为 autoload 目录下的脚本不会在启动时被加载,
它们只有在有关函数被用到时才会找到对应的文件, 然后把整个文件都加载进来.

当实现了上面的异步调用接口之后, 我们便可以实现对应的函数调用和命令了:

```vim
function! s:YoudaoCursorTranslate()
    call s:translator.start(expand("<cword>"))
endfunction

command! Ydc call <SID>YoudaoCursorTranslate()
```
