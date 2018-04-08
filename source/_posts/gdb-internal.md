---
title: GDB 实现原理介绍
date: 2018-04-04 16:46:08
toc: true
categories: Linux
tags:
    - linux
    - gdb
    - ptrace
---

GDB 是调试程序的利器, 它可以在代码中设置断点, 在程序运行过程中修改变量值等.
你是不是也很好奇 GDB 是如何实现这些功能的? 本文会解答你的疑问,
并通过一些简单的代码来模拟其中的实现细节.

<!--more-->

# ptrace 介绍

GDB 中的魔法般的操作底层都是通过 ptrace 调用来实现的, 在介绍 GDB 的具体实现细节前,
我们先来好好了解下 ptrace 调用.

从名字就可以看出 ptrace 系统调用是用于进程跟踪的, 当进程调用了 ptrace 跟踪某个进程之后:

* 调用 ptrace 的进程会变成被跟踪进程的父进程;
* 被跟踪进程的进程状态被标记为 `TASK_TRACED`;
* 发送给被跟踪子进程的信号 (SIGKILL 除外) 会被转发给父进程, 而子进程会被阻塞;
* 父进程收到信号后, 可以对子进程进行检查和修改, 然后让子进程继续执行;

在 `man ptrace` 中可以找到 ptrace 的定义原型:

```c
#include <sys/ptrace.h>
long ptrace(enum __ptrace_request request, pid_t pid, void *addr, void *data);
```

其中 `request` 参数指定了我们要使用 ptrace 的什么功能, 大致可以分为以下几类:

* PTRACE_ATTACH 或 PTRACE_TRACEME 建立进程间的跟踪关系;
    * PTRACE_TRACEME 是被跟踪子进程调用的, 表示让父进程来跟踪自己, 通常是通过 GDB 启动新进程的时候使用;
    * PTRACE_ATTACH 是父进程调用 attach 到已经运行的子进程中; 这个命令会有权限的检查, non-root 的进程不能 attach 到 root 进程中;
* PTRACE_PEEKTEXT, PTRACE_PEEKDATA, PTRACE_PEEKUSR 等读取子进程内存/寄存器中保留的值;
* PTRACE_POKETEXT, PTRACE_POKEDATA, PTRACE_POKEUSR 等修改被跟踪进程的内存/寄存器;
* PTRACE_CONT，PTRACE_SYSCALL, PTRACE_SINGLESTEP 控制被跟踪进程以何种方式继续运行;
    * PTRACE_SYSCALL 会让被调用进程在每次 进入/退出 系统调用时都触发一次 SIGTRAP; strace 就是通过调用它来实现的, 在每次进入系统调用的时候读取出系统调用参数, 在退出系统调用的时候读取出返回值;
    * PTRACE_SINGLESTEP 会在每执行完一条指令后都触发一次 SIGTRAP; GDB 的 nexti, next 命令都是通过它来实现的;
* PTRACE_DETACH, PTRACE_KILL 脱离进程间的跟踪关系;
    * 当父进程在子进程之前结束时, trace 关系会被自动解除;

参数 pid 表示的是要跟踪进程的 pid, addr 表示要监控的被跟踪子进程的地址.

# GDB 断点的实现原理

当我们用 GDB 设置断点时, GDB 会把断点处的指令修改成 `int 3`, 同时把断点信息及修改前的指令保存起来.
当被调试子进程运行到断点处时, 便会执行 `int 3`命令, 从而产生 SIGTRAP 信号.
由于 GDB 已经用 ptrace 和调试进程建立了跟踪关系, 此时的 SIGTRAP 信号会被发送给 GDB,
GDB 通过和已有的断点信息做对比 (通过指令位置) 来判断这次 SIGTRAP 是不是一个断点.

如果是断点的话, 就回等待用户的输入以做进一步的处理. 如果用户的命令是继续执行的话,
GDB 就会先恢复断点处的指令, 然后执行对应的代码.

可以看到断点的实现中需要 GDB 去修改被跟踪子进程的内存 (代码也是保存在内存中的),
下面就先介绍下如何通过 ptrace 去修改子进程的内存.

## 修改子进程内存

我们通过下面的例子来演示父进程如何修改子进程的内存:

* 父进程创建子进程, 并先让子进程 sleep 一段时间以保证父进程能更早运行;
* 父进程通过 `PTRACE_ATTACH` 来和子进程建立跟踪关系;
* 父进程修改子进程的内存数据;
* 父进程通过调用 `PTRACE_CONT` 让子进程恢复执行;

完整的代码如下所示:

```c
#include <sys/ptrace.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define SHOW(call) ({ int _ret = (int)(call); printf("%s -> %d\n", #call, _ret); if (_ret < 0) { perror(NULL); }})

char changeme[] = "This is  a test";

int main (void) {
    pid_t pid = fork();
    int ret;
    int i;
    union {
        char cdata[8];
        int64_t data;
    } u = { "Hijacked" };

    switch (pid) {
        case 0: /* child */
            sleep(2);
            printf("Children Message: %s\n", changeme);
            exit(0);

        case -1:
            perror("fork");
            exit(1);
            break;

        default: /* parent */
            SHOW(ptrace(PTRACE_ATTACH, pid, 0, 0));
            SHOW(ptrace(PTRACE_POKEDATA, pid, changeme, u.data));
            SHOW(ptrace(PTRACE_CONT, pid, 0, 0));
            printf("Parent Message: %s\n", changeme);
            wait(NULL);
            break;
    }

    return 0;
}
```

上面代码的输出是:

```txt
Children Message: Hijacked a test
ptrace(PTRACE_ATTACH, pid, 0, 0) -> 0
ptrace(PTRACE_POKEDATA, pid, changeme, u.data) -> 0
ptrace(PTRACE_CONT, pid, 0, 0) -> 0
Parent Message: This is  a test
```

可以看出子进程中的字符串已经被修改了, 而父进程中的字符串依旧保持不变.

在调用 `ptrace(PTRACE_POKEDATA, pid, changeme, u.data)` 时, 最后一个参数实际上是按照 `int64_t` 来处理的.

## 模拟 GDB 设置断点

这部分原理其实很简单, 但代码实现会稍微有些复杂. 等有人有需求时再写吧... To Be Done... :)

# References

* [ptrace运行原理及使用详解](https://blog.csdn.net/edonlii/article/details/8717029)
* [Ptrace 详解](http://www.cnblogs.com/tangr206/articles/3094358.html)
