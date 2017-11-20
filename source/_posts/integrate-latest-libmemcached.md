---
title: 在代码库中集成 1.0.28 版本的 libmemcached
date: 2017-11-20 10:28:57
toc: true
tags:
    - automake
---

最近一段时间，我们的线上 server 发生了一个很诡异的现象：在访问 memcached 的时候，
某些情况下可能会获取到旧的数据，从而导致我们的 server 不能正常地返回 response 。
我们代码库中的 libmemcahed 是一个很低的版本：0.26，我们便想通过升级 libmecached 
到最新 [1.0.28](https://launchpad.net/libmemcached/+download) 版本来尝试解决这个问题。

<!--more-->

在集成 libmemcachd 之前，我们需要先在本地把它编译出来。因为我们不需要 sasl 的功能，
便在 config 的时候把它禁用掉了：

```shell
cd libmemcached-1.0.18
./configure --disable-sasl
make
```

有两种方式可以把 libmemcachd 集成进去：

## 直接链接静态库的方式集成

这需要先把头文件添加到系统搜索路径中，同时把之前编译好的 library (libmemcached-1.0.18/libmemcached/.libs/libmemcached.a) 静态库添加到代码库，
并加入到链接库参数中：

```automake
AM_CPPFLAGS += -isystem $(top_srcdir)/3rd/libmemcached

ads_LDADD += $(root_path)/3rd/3rd/libmemcached.a
```

## 集成 libmemcachd 代码

集成 libmemcachd 静态库的方式更简单，能够让我们快速地进行一些测试。
更优雅的集成方式还是集成进 libmemcachd 的代码，让它每次和我们的代码一起 build 。

首先我们需要把 libmemcachd 的代码复制到我们的代买库中，在复制之前需要用 `make clean` 清理下编译生成的中间文件。
同时，如果是在非 windows 环境下编译，且把 libmemcachd 通过 `-isystem` 方式加到搜索路径时，我们需要删除掉 poll.h 文件。

```shell
cp libmemcached-1.0.18/libmemcached 3rd/libmemcached
cp libmemcached-1.0.18/libhashkit-1.0/ 3rd/libmemcached
cp libmemcached-1.0.18/libmemcached-1.0/ 3rd/libmemcached
cp libmemcached-1.0.18/libmemcachedprotocol-0.0/ 3rd/libmemcached
cp libmemcached-1.0.18/libhashkit 3rd/libmemcached
```

在 3rd/libmemcached 中加入 Makefile.am 文件：

```automake
AM_CFLAGS = --std=c99 -D_POSIX_C_SOURCE
LIBMEMCACHED_ROOT = $(top_srcdir)/3rd/libmemcached
AM_CPPFLAGS = -I$(LIBMEMCACHED_ROOT) -I$(LIBMEMCACHED_ROOT)/libmemcached

LIBMEMCACHED_SOURCES = \
	$(LIBMEMCACHED_ROOT)/libmemcached/csl/context.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/csl/parser.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/csl/scanner.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/instance.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/allocators.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/allocators.hpp \
	$(LIBMEMCACHED_ROOT)/libmemcached/analyze.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/array.c \
	$(LIBMEMCACHED_ROOT)/libmemcached/auto.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/backtrace.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/byteorder.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/callback.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/connect.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/delete.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/do.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/dump.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/error.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/exist.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/fetch.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/flag.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/flush.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/behavior.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/flush_buffers.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/get.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/hash.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/hash.hpp \
	$(LIBMEMCACHED_ROOT)/libmemcached/hosts.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/initialize_query.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/io.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/key.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/memcached.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/encoding_key.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/namespace.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/options.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/parse.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/poll.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/purge.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/quit.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/quit.hpp \
	$(LIBMEMCACHED_ROOT)/libmemcached/response.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/result.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/server.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/server_list.hpp \
	$(LIBMEMCACHED_ROOT)/libmemcached/server_list.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/stats.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/storage.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/strerror.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/string.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/touch.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/udp.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/verbosity.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/version.cc \
	$(LIBMEMCACHED_ROOT)/libmemcached/virtual_bucket.c \
	$(LIBMEMCACHED_ROOT)/libmemcached/sasl.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_aes.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_algorithm.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_behavior.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_crc32.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_digest.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_encrypt.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_fnv_32.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_fnv_64.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_function.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_has.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_hashkit.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_hsieh.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_jenkins.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_ketama.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_md5.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_murmur.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_murmur3.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_murmur3_api.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_nohsieh.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_one_at_a_time.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_rijndael.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_str_algorithm.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_strerror.cc \
	$(LIBMEMCACHED_ROOT)/libhashkit/libhashkit_string.cc

noinst_LIBRARIES = libmemcached.a 

libmemcached_a_SOURCES = $(LIBMEMCACHED_SOURCES)

CFLAGS += -Wno-pointer-bool-conversion -Wno-self-assign
```

同时把 libmemcachd 的 Makefile 加到 configure.ac 文件中：

```config
AC_CONFIG_FILES([ 3rd/libmemcached/Makefile ])
```

## 遇到的一些坑

### 禁用 sasl 的问题

最开始编译的时候没有加 `--disable-sasl`，导致编译的时候一直提示 sasl 相关的库找不到。
加上这个编译参数之后会在文件 `libmemcached-1.0.18/libmemcached-1.0/configure.h` 里添加下面的宏：

```cpp
#define LIBMEMCACHED_WITH_SASL_SUPPORT 0
```

注意一定要复制正确的 configure.h 文件到到代码库中！

### poll.h 的问题

刚开始一直会提示 'POLLIN' 之类的变量找不到的问题，检查 libmemcachd 里的 poll.h 文件中是有这个变量的定义的。
再仔细看才发现这个文件定义的变量只有在 windows 下才会生效。

而且因为我们用 `-isystem` 把 libmemcachd 目录加了进去，导致编译的时候会用 limcached 里的 poll.h 替换了系统中的这个文件，
但 libmemcachd 的 poll.h 文件在 linux 下又是无效的，从而会导致 'POLLIN' 找不到之类的编译错误。我们把 poll.h 这个文件从 libmemcachd
中删除就可以解决这个问题。
