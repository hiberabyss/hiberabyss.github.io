---
title: 「Docker」网络调试的一个小技巧
date: 2018-02-07 11:28:28
toc: true
tags:
    - Docker
---

有时当容器地网络出现问题时需要我们利用一些命令进行调试, 但容器内部却没有安装这些调试工具;
这时我们可以新建一个容器, 让它和之前的容器共享同一个 Network Namespace , 这样我们便可以在新容器中调试之前容器地网络问题了.

<!--more-->

# 示例

当我们启动 nginx 容器, 想检查容器中的 80 端口是否开启时会发现没有对应地命令:

```txt
[ec2-user@ip-10-24-254-11 ~]$ docker run --name nginx -d nginx
dce80ba20d033e32195afb92ee4c794aa248066c52fb5c78c6bb452927ed57cb
[ec2-user@ip-10-24-254-11 ~]$ docker exec -it nginx bash
root@dce80ba20d03:/# nc -zv localhost 80
bash: nc: command not found
root@dce80ba20d03:/# wget -q -O- localhost:80
bash: wget: command not found
root@dce80ba20d03:/#
```

这时我们可以基于容器 nginx 的 Network Namespace 启动一个新的容器:

```txt
[ec2-user@ip-10-24-254-11 ~]$ docker run --name debug -it -d --net container:nginx busybox
af3abd9b1cb13b106e452cc97387b042f841ae16e5ad3ba1eaeccab98d0f6f96
```

这时便可在新建的 debug 容器中调试之前容器的网络了:

```txt
[ec2-user@ip-10-24-254-11 ~]$ docker exec -it debug sh
/ # nc -zv localhost 80
localhost (127.0.0.1:80) open
```
