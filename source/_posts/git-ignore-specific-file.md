---
title: 「Git」在 merge 的时候忽略特定的文件
date: 2018-03-03 22:06:53
toc: true
categories: Git
tags:
    - Git
---

有时当我们 merge 别的分支到当前分支时, 希望当前分支的某个文件能保持不变.
例如在更新 Hexo 主题时保证 `_config.yml` 文件不变, 以减少合并冲突的产生.
本文会介绍如何通过 gitattributes 来实现这个目标.

<!--more-->

# 如何实现

首先需要添加一个 merge driver:

```sh
git config --global merge.ours.driver true
```

然后在项目的根目录下添加一个文件 `.gitattributes` , 在文件里添加需要被忽略的文件:

```txt
_config.yml merge=ours
```

# Demo

<script src="https://asciinema.org/a/6KLaDnj58eB7CQ6BDWPqY9udv.js" id="asciicast-6KLaDnj58eB7CQ6BDWPqY9udv" async></script>

# 原理

在 `.gitattributes` 里可以设置文件的 merge driver, 我们先是添加了一个名叫 `ours` 的 merge driver,
这个 driver 被设定为 `true` , 也就是使用这个 merge driver 的文件在 merge 的时候什么都不会做,
也就会保持不变.

# References

* [How to make Git preserve specific files while merging](https://medium.com/@porteneuve/how-to-make-git-preserve-specific-files-while-merging-18c92343826b)
* [gitattributes](https://git-scm.com/docs/gitattributes#gitattributes-text)
