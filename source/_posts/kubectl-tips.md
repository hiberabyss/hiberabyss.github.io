---
title: 一些实用的 kubectl 工具
date: 2018-01-18 15:01:46
toc: true
tags:
    - K8S
    - kubectl
---

使用 K8S 的话就需要经常用到 kubectl ，有一些实用的小工具能提高我们使用 kubectl 的效率。
我把这些小工具打包放在了 [github](https://github.com/hiberabyss/k8s-tools) 上。

执行下面的命令即可安装 (安装完后可能需要执行 `source ~/.bashrc` 或 `source ~/.zshrc`) :

```sh
sh -c "$(wget -O- https://raw.githubusercontent.com/hiberabyss/k8s-tools/master/install.sh)"
```

接下来会详细介绍安装完成后会包括哪些功能.

<!--more-->

当安装文件检查到当前系统没有 `kubectl` 时, 会自动帮你安装它.
此外, 它还提供了以下几个工具：`kexe`, `kget`, `kns`, `kctx`。

# kexe

这个工具可以帮忙快速地进入 pod ：

```sh
[ec2-user@ip-10-11-111-111 ~]$ kexe demo-5d8d688c78-qcs7p sh
/ #

# using partial match
➜  .dotfiles git:(master) kexe dns-806549836-krtrf sh -n kube-system
Defaulting container name to kubedns.
Use 'kubectl describe pod/kube-dns-806549836-krtrf' to see all of the containers in this pod.
/ # %
```

这个命令接收两个参数 ：

* 第一个是 pod 名，可以部分匹配；
* 第二个是 shell 的类型，这个参数是可选项，默认是 bash 。

更详细的使用方法可以查看 `kexe -h`.

# kget

这个工具是对 `kubectl get` 的一个封装，但增加了模糊匹配的功能：

```sh
[ec2-user@ip-10-24-254-11 ~]$ kget pod dns -a
kube-system   dns-controller-5cbcd846f9-dg2kp                         1/1       Running   0          7d        10.24.255.153   ip-10-24-255-153.ec2.internal
kube-system   kube-dns-7f56f9f8c7-7qjg2                               3/3       Running   0          3h        100.96.12.3     ip-10-24-255-251.ec2.internal
kube-system   kube-dns-7f56f9f8c7-l5tvl                               3/3       Running   0          3h        100.96.11.4     ip-10-24-255-117.ec2.internal
kube-system   kube-dns-autoscaler-f4c47db64-895rk                     1/1       Running   0          3h        100.96.12.4     ip-10-24-255-251.ec2.internal
```

具体的使用方法可以查看 `kget -h`

# kns

这个命令可以用来方便地管理 k8s 的 namespaces ，直接执行 `kns` 可以显示当前所有的 namespaces ：

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
