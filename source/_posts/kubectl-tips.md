---
title: 一些实用的 kubectl 工具
date: 2018-01-18 15:01:46
toc: true
tags:
	- k8s
    - kubectl
---

使用 K8S 的话就需要经常用到 kubectl ，有一些实用的小工具能提高我们使用 kubectl 的效率。
我把这些小工具打包放在了 [github](https://github.com/hiberabyss/k8s-tools) 上。
执行命令 `sh -c "$(wget -O- https://raw.githubusercontent.com/hiberabyss/k8s-tools/master/install.sh)"`
即可成功安装。下面我会详细介绍这些小工具。

<!--more-->

这个 repo 库里除了帮忙安装 `kubectl` ，还会提供以下三个工具：`kexe` 、 `kns` 、 `kctx`。

# kexe

这个工具可以帮忙快速地进入 pod ：

```sh
[ec2-user@ip-10-11-111-111 ~]$ kexe demo-5d8d688c78-qcs7p sh
/ #
```

这个命令接收两个参数，第一个是 pod 名；第二个是 shell 的类型，这个参数是可选项，默认是 bash 。

# kns

这个命令可以用来快速地管理 k8s 的 namespaces ，直接执行 `kns` 可以显示当前所有的 namespaces ：

```sh
[ec2-user@ip-10-24-111-153 ~]$ kns
default
kube-public
kube-system
```

执行 `kns namespace_name` 就可以直接切换到对应的 namespace 。

# kctx

kctx 的用法类似 kns ， 只不过它是用来管理 k8s context ：

```sh
[ec2-user@ip-10-11-250-153 ~]$ kctx
bchip2.k8s.local
```
