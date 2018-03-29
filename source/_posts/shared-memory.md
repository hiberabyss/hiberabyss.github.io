---
title: 进程间通信： 共享内存
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

# 使用 shm 机制

shm 基于 key 来标识一块共享内存区域, 使用 `shmget` 来创建或获取一段已经存在的共享内存.
当多个进程通过同一个 key 调用 `shmget` 时, 它们会把同一块内存区域映射到自己的地址空间中.

## 读写者模型

假定存在一个读者进程和一个写着进程, 它们共用一段共享内存, 按照如下的模式工作:

* 写者进程往共享内存中写数据; 写完数据后通知读者进程并进入阻塞状态, 等待读者进程发送信号, 然后接着等待用户的输入;
* 读者进程等待写者进程的信号, 收到后会打印共享内存中的字符串到 stdout, 发送信号给写者进程, 然后进入阻塞状态;

当写者进程检查到用户的输入是 `quit` 时, 便会先给读者进程发送信号, 然后开始进入退出模式, 开始清理共享内存.
当读者进程检测到共享内存中的字符串为 `quit` 时便会直接退出.

### 如何获取对方的 PID

为了能够给对方发送信号, 读者写着需要知道对方的 PID , 这个信息也是通过共享内存获取的:

* 当任何一个进程先启动时, 便会创建共享内存, 同时把自己的 PID 写到共享内存中, 然后进入阻塞状态.
* 当后启动的进程检测到共享内存已经存在时, 便从共享内存里读取到对方的 PID 并保存在自己的内存变量里; 同时在共享内存中保存自己的 PID, 给对方进程发送信号;
* 当先启动的进程接收到信号后, 便从共享内存中读取对方的 PID 并保存到自己的内存变量里

## Demo

* 启动 writer
* 启动 reader
* 在 writer 处输入 `hello`; reader 处会输出 `hello`
* 再 writer 处输入 `quit`; writer 和 reader 都会退出

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520873559834.png" width="570"/>

## 代码实现

相关的代码在 [Github](https://github.com/hiberabyss/JustDoIt/tree/master/ShareMemory) 上,
下载下来后可直接用 `make` 生成 writer 和 reader.

# 使用 mmap 来实现内存共享

不同于 shm , mmap 并不是专门为共享内存设计的. 它的主要作用是把文件内容映射到内存地址空间中,
可以像访问内存一样访问文件, 从而避免调用 `read` `write` 等高开销的系统调用, 提高文件的访问效率.

在 mmap 的参数中, 我们可以添加一个 `MAP_SHARED` 标志, 这样当多个进程 mmap 同一个文件的相同部分内容的时候,
它们使用的是同一块内存区域.

## 示例

我们创建两个读写进程, 读进程每隔 2s 输出共享内存里的内容; 写进程会修改共享内存内容, 最终读进程会打印出修改后的内容.
代码保存在 [Github](https://github.com/hiberabyss/JustDoIt/tree/master/ShareMemory/mmap) 上.

通过匿名文件映射, 我们也能实现父子进程间的内存共享. [这儿](https://github.com/hiberabyss/JustDoIt/blob/master/ShareMemory/mmap/anonymous.c)
是详细代码实现.

## mmap 的一些 tips

我们可以通过给 mmap 加上 `MAP_PRIVATE` 标志来防止程序修改文件的内容.

在通过 mmap 把文件映射进内存后, 我们能操作的整个内存范围是系统中能容纳这些文件内容的最少的页.
例如我们映射了 2 页文件内容到内存, 则我们最多只能操作 2 页内存; 如果我们映射了 1.5 页文件内容到内存,
我们也是最多能操作 2 页内存.

# References

- [进程间通信之-共享内存Shared Memory--linux内核剖析](http://blog.csdn.net/gatieme/article/details/51005811)
- [Linux进程间内存共享机制mmap详解](http://blog.csdn.net/maverick1990/article/details/48050975)
