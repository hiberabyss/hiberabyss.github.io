---
title: 基于 Seafile 自建网盘
date: 2020-05-06 18:50:13
toc: true
categories:
tags:
    - 网盘
---

现在公司给配置了 iMac 和 Macbook，平时在公司时就用 iMac，在家的时候会用 Macbook，多个终端就涉及到一些数据的同步，
例如一些配置文件、写了一半的 PPT 等。最开始尝试过使用国内的微云等网盘来进行同步，但发现同步速度很慢，
而且经常出现一些莫名其妙的同步错误。后面用过一段时间的 Dropbox，但在家时使用的翻墙工具很不稳定，
经常出现无法连接 Dropbox 的问题，而且 Dropbox 的免费空间也很小，要是同步一些大文件就显的不够用。

因为在公司可以申请一些个人使用的开发容器，磁盘空间有 500GB 左右，就考虑可以自己搭建一个同步网盘，
这样就不会被限速，而且空间也只受硬盘大小的限制；唯一的缺点就是需要连上公司的 VPN 才能使用网盘，
但毕竟也会经常同步一些公司内部的资料，连 VPN 才能使用也是一种安全保险，避免一不小心就 “高压线了”。

<!--more-->

# 如何搭建 Seafile 网盘服务

可以很方便的使用 docker 来搭建 Seafile 服务：

```sh
sudo docker run -d --name seafile \
  -e SEAFILE_SERVER_HOSTNAME=seafile.example.com \
  -v /data/seafile-data:/shared \
  -p 80:80 \
  seafileltd/seafile:latest
```

然后在浏览器里通过机器 IP 访问对应的 Web 服务创建账号，再下载 Seafile [客户端](https://www.seafile.com/download/)就可以使用了。
我是在 `/etc/hosts` 里加上了类似下面的配置，这样就可以直接通过 `hbliu.com` 来访问 Seafile 服务了。

```config
192.168.0.123 hbliu.com
```
