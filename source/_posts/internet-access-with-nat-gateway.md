---
title: 【AWS】利用 NAT Gateway 给 EC2 增加外网访问
date: 2018-01-18 10:17:48
toc: true
tags:
	- AWS
---

默认在 AWS 上让一个 EC2 能访问外网需要它有一个 Public IP ，
但 Public IP 是很有限的资源，我们可以利用 NAT Gateway 来通过一个 Public IP
实现多台 EC2 的外网访问。

<!--more-->

# 实现原理

NAT Gateway 会绑定到某个 subnet(属于某个 VPC) 上，这个 subnet 需要是一个 Public Subnet ，
也就是这个 subnet 的 route table 上需要有类似如下的配置：

```txt
0.0.0.0/0 igw-66666666
```

上面的配置表示这个 subnet 的默认流量会通过 Internet Gateway `igw-66666666` 出去。

为了实现 Private subnet 里的 EC2 通过 NAT Gateway 访问外网，我们需要有如下的配置：

1. 一个 Public Subnet：net1；Route Table 上配置了对应的Internet Gateway；
2. 一个 Private Subnet：net2；net2 需要和 net1 在同一个 VPC 下，如果他们俩没法直接互联，可能是 subnet 上的 ACL 的设置问题；
3. 一个 NAT Gateway：需要创建在 net1 内。

# 创建 NAT Gateway

选择 VPC Dashboard，点击 Create NAT Gateway，再在新的界面里选择一个 Public Subnet 即可：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1516245513504.png" width="536"/>

# 配置 Private Subnet 的 Route Table

选中对应的 Private Subnet 界面，在下面的界面中点中 Route Table ，把默认网关改成我们创建的
NAT Gateway 即可。注意这里的 Route Table 不能和 Public Subnet 的 Route Table 一样。

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1516247418560.png" width="607"/>

# Troubleshooting

如果配置中间出现问题可以参看 [AWS 官方文档](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html#nat-gateway-troubleshooting) 进行调试。
