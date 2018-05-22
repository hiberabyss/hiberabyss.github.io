---
title: 基于 Quorum 集群搭建讲解如何从 docker-compose 迁移到 Kubernetes
date: 2018-05-21 18:19:05
toc: true
categories: Kubernetes
tags:
    - Kubernetes
    - Quorum
---

我们经常会遇到搭建多节点集群得需求, 例如摩根推出的基于以太坊的区块链 [Quorum](https://github.com/jpmorganchase/quorum).
对于这种搭建多借点得需求, 我一般都是先通过 docker-compose 在本地实现多节点,
然后再基于 docker-compose 迁移到 Kubernetes .

这样做是因为基于 docker-compose 来实现要简单很多:

* 调试很方便;
* 多节点间通过 Volume Map 可以很容易地实现数据共享;

同时, 我们在实现 docker-compose 多节点阶段的很多工作, 如创建 Docker Image 及编写 `entrypoint.sh` 等,
都可以在往 Kubernetes 上迁移时被复用到. 基于 docker-compose 的多节点环境也能作为开发环境使用.

<!--more-->

# 基于本机 Volume Map 数据共享的多借点搭建

在网上搜索 Quorum 的集群搭建时搜索到了 [这个](https://github.com/lucassaldanha/quorum-docker-Nnodes)
实现方法. 它主要是通过 Shell 脚本提前生成好每个节点所需要得数据, 然后再分别 map 到对应的节点中.

原方案因为 geth 的更新, 在创建 contract 的时候会报错, 我对这个问题做了修复, 把修复好之后的
代码存放在 [Github](https://github.com/hiberabyss/quorum/tree/master/docker-deploy) 上.

## 运行 Quorum 集群

1. 首先执行初始化脚本 `./setup.sh` , 生成节点需要的数据及对应的 `docker-compose.yml` 文件; 其中
`setup.sh` 可以接收一个指定节点数量得参数;
```shell
➜  docker-deploy git:(master) ./setup.sh 5
[1] Configuring for 5 nodes.
[2] Creating Enodes and static-nodes.json.
[3] Creating Ether accounts and genesis.json.
WARN [05-22|04:52:46] No etherbase set and no accounts found as default
WARN [05-22|04:52:49] No etherbase set and no accounts found as default
WARN [05-22|04:52:52] No etherbase set and no accounts found as default
WARN [05-22|04:52:55] No etherbase set and no accounts found as default
WARN [05-22|04:52:58] No etherbase set and no accounts found as default
[4] Creating Quorum keys and finishing configuration.
Node 1 public key: lxXXlk1QBVoR9Y7C6/Ok13oXmqK8Vf0H1YREln9z8Gg=
Node 2 public key: wLBfII80GiQK+1SSRU/7feuY9uHgtDY6gbNUGHJUGUA=
Node 3 public key: KL6AOgHe/odYTGUw8uXAUuBHN2XTzv7qboylTL8FFjM=
Node 4 public key: TgHZCt5cCnYq5k2PvUUYoYZLGGAmitFtvc1WSUgDeGQ=
Node 5 public key: JkFVrzMKOocv0LLMdd7kIXLAMXgpvp49QNQLjKC61WI=
```
2. 紧接着就可以调用 `docker-compose up -d` 来启动集群;
3. 集群启动后会创建 5 个 Quorum 的 container, 我们可以进入任一个 container 执行创建
smart contract 的操作:
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1526965078961.png" width="941"/>
4. 这里创建的 smart contract 只是一个简单的整数存取, 我们在 js 文件里创建了一个 `storage` 的
contract 对象, 可以通过它来调用 smart contract 的操作:
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1526965259018.png" width="492"/>
5. 我们可以进入别的节点, 加载我们之前创建的 smart contract :
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1526965507179.png" width="750"/>
6. 然后读取 smart contract 保存的整数值:
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1526965565536.png" width="377"/>

由此可见整个集群是正常工作的.

# 去除数据共享的本机多节点搭建

由于 Kubernetes 上不同 POD 之间共享数据相对会比较麻烦, 而上一个实现方法需要各个节点能够
共享提前生成好的数据. 经过分析我们可以发现不同节点需要共享的数据主要包括以下这些:

* 每个节点的 `static-nodes.json` 需要填写上其它节点的 IP ;
* 每个节点的 `tm.conf` 文件中需要包括别得节点在 Quorum 系统中的 ID ; 

这里我们可以通过 http server 的方式来实现不同节点间的数据共享: 

* 我们可以在节点内部获取 IP 及 ID 等信息, 将它们保存在文件 `env.sh` 中;
* 然后通过 `python -m SimpleHTTPServer 80 &` 启动一个 http server ;
* 别的节点就可以通过访问 `nodename/env.sh` 来获取必要得其它节点的信息;

基于上面的思路, 我实现了不需要通过 Volume Map 共享数据的本机多节点集群得搭建.
具体得代码放在了 [noscript-docker](https://github.com/hiberabyss/quorum/tree/master/noscript-docker),
其中主要得逻辑处理都在文件 `entrypoint.sh` 中.

# 实现在 Kubernetes 上搭建多机集群

其实上一步已经完成了大部分的工作, 接下来我们只需要创建对应的 `statefulset` 文件即可.
这里我们基于 helm 来实现对应得脚本文件. 对应的 `templates/statefulset.yaml` 文件
内容如下所示:

```yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: quorum
spec:
  serviceName: quorum
  replicas: {{ .Values.replicaCount }}
  podManagementPolicy: Parallel
  updateStrategy:
    type: OnDelete
  template:
    metadata:
      labels:
        app: quorum
    spec:
      containers:
      - name: quorum
        imagePullPolicy: Always
        image: hbliu/quorum-k8s:latest
        env:
        - name: NODE_NUMBER
          value: "{{ .Values.replicaCount }}"
        - name: NODE_PREFIX
          value: "quorum-"
```

其中的配置信息都存放在了 `values.yaml` 文件中:

```yaml
replicaCount: 10

image:
  repository: hbliu/quorum-k8s
```

[这里](https://github.com/hiberabyss/quorum/tree/master/helm/quorum) 存放了
完整的 helm 包内容.

# 总结

本文首先介绍了如何基于 Volume 映射实现多机节点间的数据共享来搭建多机节点; 接着通过 http server
的方式去除不同节点间的数据共享依赖, 最后再基于它来实现 Kubernetes 的部署脚本.
