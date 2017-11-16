---
title: 【Neovim】基于自定义 keyword 的自动补全
date: 2017-11-16 12:56:38
toc: true
tags:
	- VIM
	- neovim
---

有时我们会期望能够根据自定义的一些 keyword 来在 VIM 里进行补全。
我们可以通过 neovim 的插件 deoplete 来实现这个目的。

<!--more-->

例如我们在 VIM 里写 sql 的时候可能会遇到很长的列名：

```sql
select
transaction__request__context__custom_asset_id
from transaction;
```

我们可以把这些 keyword 保存在一个文件 `keyword.txt` 里：

```txt
transaction__request__context__custom_asset_id	varchar
```

上面的第二个字段是为了能在补全窗口里显示这个字段的类型。通过添加 deoplete 的 source 来解析这个
`keywork.txt` 文件就可以在 vim 里实现自动补全：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1510809654151.png" width="478"/>

## 如何添加 deoplete 的 source

首先需要安装 [deoplete](https://github.com/Shougo/deoplete.nvim) 插件：

```vim
Plug 'https://github.com/Shougo/deoplete.nvim'
```

把下面的内容保存到 `deoplete.nvim/rplugin/python3/deoplete/source/keyword.py`,
并把 `keyword.txt` 文件保存到相同的目录：

```vim
from os.path import getmtime, dirname, realpath
from collections import namedtuple
from .base import Base

DictCacheItem = namedtuple('DictCacheItem', 'mtime candidates')

class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'lqs'
        self.mark = '[LQS]'
        self.filetypes = ['sql']

        self.__cache = {}

    def on_event(self, context):
        self.__make_cache(context)

    def gather_candidates(self, context):
        self.__make_cache(context)

        candidates = []
        for filename in [x for x in self.__get_dictionaries(context)
                         if x in self.__cache]:
            candidates.append(self.__cache[filename].candidates)
        return {'sorted_candidates': candidates}

    def __make_cache(self, context):
        for filename in self.__get_dictionaries(context):
            mtime = getmtime(filename)
            if filename in self.__cache and self.__cache[
                    filename].mtime == mtime:
                continue
            with open(filename, 'r', errors='replace') as f:
                self.__cache[filename] = DictCacheItem(
                        mtime, [{'word': x.split('\t')[0], 'kind': x.split('\t')[1]}
                            for x in sorted([x.strip() for x in f], key=str.lower)
                                if len(x.split('\t')) > 1]
                )

    def __get_dictionaries(self, context):
        return [dirname(realpath(__file__)) + "/keyword.txt"]
```

## For FreeWheel Guys

我已经把 logquery 的关键词补全打包成一个 vim 插件包，放在了 gitlab 上，可以直接通过下面的命令
安装：

```vim
Plug 'https://github.com/Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" need to be after deoplete plugin to take effect
Plug 'git@git.dev.fwmrm.net:vim/deoplete-fwlqs.git'
```

