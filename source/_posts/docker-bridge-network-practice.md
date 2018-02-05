---
title: 自己动手实现 Docker bridge network
date: 2018-02-02 16:45:19
toc: true
tags:
    - docker
---

最近详细了解了 Docker 的网桥网络的工作原理, 便想一步一步地实现 Docker 地网桥网络.

<!--more-->

# Docker 网桥网络工作原理

Docker 的网络实现主要会用到以下功能:

* Network Namespace: 用于隔离容器和宿主机之间地网络;
* Veth 设备对: 用于连接宿主机和容器, 每个容器都会有一对 Veth 设备, 一个在容器内, 一个在宿主机内;
* 网桥: 通过网桥可以很方便地管理宿主机上的多个 veth 设备, 同时实现不同容器之间地互联;
* Iptables/NetFilter: SNAT 以实现容器内对外网的访问; 实现容器地端口映射等;
* 路由

详细原理如下图所示 (转自这篇[博客](https://draveness.me/docker)):

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1517801503362.png" width="473"/>

# 创建 Network Namespace

通过命令 `sudo ip netns add ns1` 即可创建名为 ns1 的 network namespace, 我们可以通过下面地命令查看当前系统中已有的 network namespace:

```sh
[ec2-user@ip-10-24-254-11 ~]$ sudo ls -1 /var/run/netns
ns1
```

Note: 我们可以通过命令 `sudo ip netns del ns1` 来删除之前创建地 network namespace.

# 创建 veth 设备对 

通过下面的命令创建:

```sh
[ec2-user@ip-10-24-254-11 ~]$ sudo ip link add veth0 type veth peer name veth1

[ec2-user@ip-10-24-254-11 ~]$ ip addr show | grep veth
311: veth1@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN group default qlen 1000
312: veth0@veth1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN group default qlen 1000
```

我们把 veth1 移动到 ns1 namespace 里: `sudo ip link set veth1 netns ns1`. 现在我们在宿主机中就看不到 veth1 了:

```sh
[ec2-user@ip-10-24-254-11 ~]$ ip addr show | grep veth
312: veth0@if311: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
```

当我们切换到 ns1 就可以查看到 veth1 了:

```txt
[ec2-user@ip-10-24-254-11 ~]$ sudo ip netns exec ns1 bash

[root@ip-10-24-254-11 ec2-user]# ip addr show
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
311: veth1@if312: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 3e:a0:ce:a7:8f:4c brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Note: 可以通过 `sudo ip del link veth0` 来删除这个设备对.

# 创建网桥并实现 veth1 和宿主机的互联

我们在系统默认 namespace 创建网桥 `br-demo`, 并将 veth0 加入到网桥中:

```sh

[ec2-user@ip-10-24-254-11 ~]$ sudo brctl addbr br-demo
[ec2-user@ip-10-24-254-11 ~]$ sudo brctl addif br-demo veth0
[ec2-user@ip-10-24-254-11 ~]$ sudo brctl show | grep 'br-demo'
br-demo         8000.0aa51a826228       no              veth0
```

我们给网桥添加 ip 地址: `sudo ifconfig br-demo 172.8.0.1`. 同时启动 veth0 `sudo ip link set dev veth0 up`. 再登录进 ns1 namespace 给 veth1 设置 ip 地址:

```txt
[root@ip-10-24-254-11 ec2-user]# ifconfig veth1 172.8.0.8
[root@ip-10-24-254-11 ec2-user]# ifconfig veth1 172.8.0.8
```

这时我们便可以 ping 通 br-demo 的地址了:

```txt
[root@ip-10-24-254-11 ec2-user]# ping -c 1 172.8.0.1
PING 172.8.0.1 (172.8.0.1) 56(84) bytes of data.
64 bytes from 172.8.0.1: icmp_seq=1 ttl=255 time=0.044 ms
```

# 给 veth1 添加外网访问

在宿主机上编辑 iptables , 添加以下规则:

```sh
sudo iptables -t filter -A FORWARD -i br-demo ! -o br-demo -j ACCEPT
sudo iptables -t filter -A FORWARD -i br-demo -o br-demo -j ACCEPT
sudo iptables -t filter -A FORWARD -o br-demo -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

sudo iptables -t nat -A POSTROUTING -s 172.8.0.0/16 ! -o br-demo -j MASQUERADE
```

在 ns1 namespace 里测试是否可以连通外网:

```txt
[root@ip-10-24-254-11 ec2-user]# ping baidu.com -c1
PING baidu.com (111.13.101.208) 56(84) bytes of data.
64 bytes from 111.13.101.208: icmp_seq=1 ttl=39 time=258 ms
```

# 映射 ns1 内部端口到宿主机

我们现在 ns1 内部通过 python 启动一个简单地 http server:

```txt
[root@ip-10-24-254-11 ec2-user]# python -m SimpleHTTPServer
Serving HTTP on 0.0.0.0 port 8000 ...
```

在宿主机上我们可以通过 veth1 的 ip 地址访问这个服务:

```txt
[ec2-user@ip-10-24-254-11 ~]$ curl -I 172.8.0.8:8000
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/2.7.12
Date: Mon, 05 Feb 2018 05:54:10 GMT
Content-type: text/html; charset=UTF-8
Content-Length: 1718
```

把下面地规则加入到 iptalbe 里, 我们便可以通过宿主机的 8088 端口访问到这个 service 了:

```sh
[ec2-user@ip-10-24-254-11 ~]$ sudo iptables -t nat -A OUTPUT -p tcp -m tcp --dport 8088 -j DNAT --to-destination 172.8.0.8:8000
[ec2-user@ip-10-24-254-11 ~]$ curl -I 10.24.254.11:8088
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/2.7.12
Date: Mon, 05 Feb 2018 05:58:00 GMT
Content-type: text/html; charset=UTF-8
Content-Length: 1718
```

# References

- [Docker 核心技术与实现原理](https://draveness.me/docker)
