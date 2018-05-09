---
title: 如何部署多节点 Tendermint 集群
date: 2018-04-11 10:47:28
toc: true
categories: Blockchain
tags:
    - Tendermint
---

这几天在忙着搭建多节点的 TenderMint 节点, 中间遇到了一些坑, 会通过这篇博客记录下整个过程.
欢迎感兴趣的同学多多交流!

<!--more-->

# 基于 docker-compose 搭建

本来是想直接在本机启动多个 `tendermint node` 节点来实现的,
后来觉得每个 node 都得设置不同的主目录, 会有点麻烦, 关键是还不能很方便地在别的环境运行.

这种搭建多节点的任务还是通过 docker 比较方便, 而且也有官方的 docker image `tendermint/tendermint`.
我们可以通过 docker-compose 来启动多个 container.

通过[官方文档](http://tendermint.readthedocs.io/en/master/deploy-testnets.html)我们知道启动 tendermint 集群需要下面几个步骤:

* 每个 node 都需要通过 `tendermint init` 来进行初始化;
* 需要有一个包含所有 validator 节点 public key 的 `genesis.json` 文件, 然后用这个文件覆盖所有节点对应的文件; 在我们的示例中所有的节点都是 validator 节点;
* 通过 `tendermint show_node_id` 获取节点的 ID, 并通过参数 `--p2p.persistent_peers=ID1@node1:46656,ID2@node2:46656` 来传入种子 peer;

这里想吐槽下官方文档和最新的代码不一致, 上面的最后一点中的 ID 在文档中没有提及,
但在最新版本的 tendermint 中, 这个 ID 又是必须的. 后来在 github 上提交了 issue 才知道怎么去获取这个 ID.

对应于上面环境准备需要做的工作, 我通过脚本文件 `./init_data.sh` 做了自动化的处理:

```sh
docker run --rm -v `pwd`/node1_data:/tendermint tendermint/tendermint init
docker run --rm -v `pwd`/node2_data:/tendermint tendermint/tendermint init

echo "Node1 ID: $(docker run --rm -v `pwd`/node1_data:/tendermint tendermint/tendermint show_node_id)"
echo "Node2 ID: $(docker run --rm -v `pwd`/node2_data:/tendermint tendermint/tendermint show_node_id)"

cat node2_data/config/genesis.json | jq ".validators |= .+ $(cat node1_data/config/genesis.json | jq '.validators')" > final_genesis.json

cp ./final_genesis.json ./node2_data/config/genesis.json
cp ./final_genesis.json ./node1_data/config/genesis.json
```

其中打印出来的节点 ID 会在后面的 `docker-compose.yml` 文件中用到.

然后我们就可以通过 `docker-compose.yml` 启动多个 container 了, 这里我们启动两个节点:

```yaml
version: '2.0'

services:

  tm_node1:
    image: hbliu/tendermint
    container_name: tm_node1
    hostname: tm_node1
    tty: true
    ports:
      - '46667:46657'
    volumes:
      - ./node1_data:/tendermint
    entrypoint: ["bash", "-c", "tendermint node --p2p.persistent_peers=d902b83f46131a80a82df2198a704889c5833284@tm_node2:46656 --moniker=`hostname` --proxy_app=kvstore --consensus.create_empty_blocks=false"]

  tm_node2:
    image: tendermint/tendermint
    container_name: tm_node2
    hostname: tm_node2
    tty: true
    environment:
      - NODE2_ID=5fc11b1d4ab4274476a2243e321e0daa47a36f3a
    ports:
      - '46668:46657'
    volumes:
      - ./node2_data:/tendermint
    entrypoint: ["bash", "-c", "tendermint node --p2p.persistent_peers=59ef92d5c6a408a59e4a1d599a8aff0d4ef37785@tm_node1:46656 --moniker=`hostname` --proxy_app=kvstore --consensus.create_empty_blocks=false"]
```

接下来我们就可以通过下面的步骤来启动有两个节点的 tendermint 集群:

```sh
./init_data.sh

# 用上面脚本的输出的节点 ID 分别去替换 docker-compose.yml 文件中的节点 ID

docker-compose up -d
```

成功启动之后我们可以通过 `curl -s localhost:46667/net_info` 中的结果来判断两个节点有没有相互识别.

具体的代码放在了 [Github](https://github.com/hiberabyss/tendermint-deploy/tree/master/docker-compose-local).

# 通过 Kubernetes 来部署

上面基于 docker-compose 的方法一般只能在单机运行, 只适合用来做一些简单验证或搭建开发环境.
通过 Kubernetes 部署的话我们就能很方便地实现集群的部署及扩容.

部署一个 tendermint 节点大致需要下面三部分工作:

* 初始化工作;
* 通过 `abci-cli` 启动应用进程;
* 启动 `tendermint node` 进程;

对应于这三部分工作我们用一个 pod 里的三个 container 来实现:

* `initContainers` 用来实现初始化相关的工作;
* 运行 `abci-cli` 的容器 `tm`;
* 运行 `tendermint node` 进程的容器 `app`

其中 `tm` 容器因为还需要给其他节点提供 ID 和 public key 信息, 所以我们还在其中启动了一个 http server,
它提供了两个接口:

* `host:port/node_id` 输出当前 tendermint node 的 ID;
* `host:port/pub_key` 输出当前 tendermint node 的 public key;

[这里](https://github.com/hiberabyss/tendermint-deploy/blob/master/docker/tmnode_server.go)
是这个 http server 的代码.

我把这个 http server 加入到官方的 image 里制作了一个新的 image `hbliu/tendermint`:

```dockerfile
FROM tendermint/tendermint:latest

ADD ./tmnode_server /usr/bin/
```

接着我们就可以在文件 `app.yaml` 中实现对应的 service, statefulset 了.
相关的代买也都放在了 [Github](https://github.com/hiberabyss/tendermint-deploy/tree/master/k8s).

# Reference

* [Deploy a Testnet](http://tendermint.readthedocs.io/en/master/deploy-testnets.html)
