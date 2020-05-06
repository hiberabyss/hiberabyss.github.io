---
title: 博客中自动插入剪贴板图片链接
date: 2020-05-06 15:37:47
toc: true
categories:
tags:
    - Blog
    - 图床
---

我是通过 Vim 写 Markdown 的方式来写博客，这种方式在需要插入剪贴板里的图片时不是很方便。
之前我是通过一些图床工具来实现剪贴板图片插入，但这里会存在两个问题：

1. 图床链接有可能会失效，这样博客里的图片就变成了不可访问的状态；
2. 在网络不好的时候，本地上传图片可能要很久，特别是我使用的是高分辨率的 imac，截图时图片大小会很大。

鉴于刚才提到的问题，我希望通过如下的方式来插入图片：

1. 通过一个 Shell 工具来保存剪贴板里的截图到博客网站的某个子目录里，并输出对应的 Markdown 图片链接；
2. 添加自定义的 Vim 命令来插入 Shell 工具输出的 Markdown 图片链接。

下面是 Shell 脚本代码，主要是基于 `pngpaste` 读取剪贴板里的图片，并按照 `md5-timestamp.jpg` 文件名保存到特定目录：

```sh
IMG_DIR="img/posts"
DEST_DIR="$HOME/Dropbox/blog/source/$IMG_DIR"

prepare() {
  if ! which pngpaste &> /dev/zero; then
    brew install pngpaste
  fi
}

markdown_link() {
  echo "![](/$IMG_DIR/$1)"
}

main() {
  prepare
  cd $DEST_DIR
  local timestamp=$(date +%s)
  local filename="${timestamp}.jpg"

  pngpaste "$filename"

  local finalname="$(md5sum $filename | awk '{print $1}')-${timestamp}.jpg"
  mv "$filename" "$finalname"
  local md_link=$(markdown_link "$finalname")
  # echo "$md_link" | pbcopy
  echo "$md_link"
}
main "$@"
```

把上面的 Shell 脚本保存为 `blogimg` 并添加可执行权限，然后在 vimrc 里加上如下的配置：

```vim
command! -nargs=0 InsertImg :r !blogimg
```

后面就可以通过执行 `InsertImg` 来直接插入剪贴板图片对应的链接：


![](/img/posts/c71d4089ae88c60aebc0916f408c18a5-1588752367.jpg)

<!--more-->

