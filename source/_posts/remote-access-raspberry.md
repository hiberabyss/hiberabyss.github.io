---
title: 【树莓派】利用 ngrok 进行远程访问
date: 2017-11-13 23:23:42
toc: true
tags: Raspberry
---

当在树莓派上开启了 ssh 服务后，我们可以通过局域网 IP 来进行访问。但如果想要通过外网访问树莓派，
就需要有一个公网的 IP 地址。我们可以利用路由器的端口转发功能，把路由器的某个端口映射到树莓派的 22 端口，
这样就可以通过路由器的公网 IP 地址和端口访问树莓派。但路由器的公网 IP 每隔一段时间就会被更新，
这样就需要先查询路由器的公网 IP ，再去访问树莓派，会比较麻烦。而通过 ngrok ，可以一劳永逸地解决外网访问树莓派的问题。

<!--more-->

## 什么是 Ngrok

简单来说，ngrok 是一个端口转发服务提供商。它在自己的服务器和运行 ngrok 命令的机器之间建立了一条 tunnel。
这条 tunnel 的两端分别是 ngrok 服务器的某个地址和端口，以及执行 ngrok 命令的机器的地址和端口。
在执行完 ngrok 命令之后，我们会收到服务器的域名和端口，这个域名是公网可见的。通过访问这个域名我们就可以访问执行 ngrok 命令的机器。

## 怎么用 Ngrok

首先需要下载 [ngrok](https://ngrok.com/download) 的二进制文件，
然后在 ngrok 的[官网](https://ngrok.com/)上进行注册，注册完成后点击 Dashboard 就可以看到你自己的 token，然后执行下面的命令：

```shell
./ngrok authtoken 5k7rUCwLksfx1qwpT17en_7tMFYmC1u8cHGeppJzic1
```

再通过下面的命令映射出树莓派的 22 端口：

```shell
./ngrok tcp 22
```

上面的命令执行完后会有下面这样的输出：

```txt
ngrok by @inconshreveable

Session Status                online
Account                       Hongbo Liu (Plan: Free)
Version                       2.2.8
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    tcp://0.tcp.ngrok.io:15393 -> localhost:22

Connections                   ttl     opn     rt1     rt5     p50     p90
                              2       0       0.00    0.00    35.11   58.65
```

我们就可以通过 `ssh -p 15393 pi@0.tcp.ngrok.io` 来访问到树莓派了。
