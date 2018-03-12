---
title: 进程间通信: 共享内存
date: 2018-03-13 00:21:02
toc: true
categories: Linux
tags:
    - IPC
    - Linux
---

Linux 中的进程通信主要包括以下几种方式:

* 管道(pipe); 流管道 (s_pipe) 和有名管道 (FIFO)
* 信号（signal）
* 消息队列
* 共享内存
* 信号量
* 套接字（socket)

本文主要介绍共享内存的使用方式, 其中也会用到信号.

<!--more-->

# 读写者模型

假定存在一个读者进程和一个写着进程, 它们共用一段共享内存, 按照如下的模式工作:

* 写者进程往共享内存中写数据; 写完数据后通知读者进程并进入阻塞状态, 等待读者进程发送信号, 然后接着等待用户的输入;
* 读者进程等待写者进程的信号, 收到后会打印共享内存中的字符串到 stdout, 发送信号给写者进程, 然后进入阻塞状态;

当写者进程检查到用户的输入是 `quit` 时, 便会先给读者进程发送信号, 然后开始进入退出模式, 开始清理共享内存.
当读者进程检测到共享内存中的字符串为 `quit` 时便会直接退出.

## 如何获取对方的 PID

为了能够给对方发送信号, 读者写着需要知道对方的 PID , 这个信息也是通过共享内存获取的:

* 当任何一个进程先启动时, 便会创建共享内存, 同时把自己的 PID 写到共享内存中, 然后进入阻塞状态.
* 当后启动的进程检测到共享内存已经存在时, 便从共享内存里读取到对方的 PID 并保存在自己的内存变量里; 同时在共享内存中保存自己的 PID, 给对方进程发送信号;
* 当先启动的进程接收到信号后, 便从共享内存中读取对方的 PID 并保存到自己的内存变量里

# Demo

* 启动 writer
* 启动 reader
* 在 writer 处输入 `hello`; reader 处会输出 `hello`
* 再 writer 处输入 `quit`; writer 和 reader 都会退出

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520873559834.png" width="570"/>

# 代码实现

相关的代码在 [Github](https://github.com/hiberabyss/JustDoIt/tree/master/ShareMemory) 上,
下载下来后可直接用 `make` 生成 writer 和 reader.

# References

- [进程间通信之-共享内存Shared Memory--linux内核剖析](http://blog.csdn.net/gatieme/article/details/51005811)

