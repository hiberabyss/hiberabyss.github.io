---
title: Kafka 入门教程
date: 2018-05-08 12:03:15
toc: true
categories: Tool
tags:
    - Kafka
---

Kafka 现在在我们公司使用的很广泛, 如用作 AdServer 的日志收集和 Counter 服务的消息系统等.

本文会先介绍下 Kafka 的一些基本概念, 然后介绍如何搭建 Kafka 集群和如何使用,
最后会简要介绍下 Kafka 文件存储的实现原理.

<!--more-->

# 基本概念介绍

* `Broker` 可以简单理解为一个 Kafka 节点, 多个 Broker 节点构成整个 Kafka 集群;
* `Topic` 某种类型的消息的合集;
    * `Partition` 它是 Topic 在物理上的分组, 多个 Partition 会被分散地存储在不同的 Kafka 节点上; 单个 Partition 的消息是保证有序的, 但整个 Topic 的消息就不一定是有序的;
    * `Segment` 包含消息内容的指定大小的文件, 由 index 文件和 log 文件组成; 一个 Partition 由多个 Segment 文件组成
        * `Offset` Segment 文件中消息的索引值, 从 0 开始计数
    * `Replica (N)` 消息的冗余备份, 表现为每个 Partition 都会有 N 个完全相同的冗余备份, 这些备份会被尽量分散存储在不同的机器上;
* `Producer` 通过 Broker 发布新的消息到某个 Topic 中;
* `Consumer` 通过 Broker 从某个 Topic 中获取消息;

# 如何使用 Kafka

首先介绍下如何搭建 Kafka 集群. 我们基于 docker-compose 来搭建一个 2 个节点的集群,
[这里](https://github.com/wurstmeister/kafka-docker) 是详细的介绍文档.

## 搭建 Kafka 集群

首先编写一个 `docker-compose.yml` 文件:

```yaml
version: '2'
services:
  zookeeper:
    image: wurstmeister/zookeeper
    ports:
      - "2181:2181"

  kafka:
    image: wurstmeister/kafka
    ports:
      - "9092"
    environment:
      KAFKA_ADVERTISED_HOST_NAME: 192.168.99.100
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_CREATE_TOPICS: test:1:1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

其中 `KAFKA_ADVERTISED_HOST_NAME` 需要被替换成你本机的 IP 地址, 不能是 `localhost` `0.0.0.0` 之类的地址.
`KAFKA_CREATE_TOPICS` 是为了演示可以在 Kafka 集群启动的时候创建一些默认的 Topic; `test:1:1`
的含义是默认创建一个名字为 `test`, Partition 和 Replica 数量都为 1 的 Topic.

在 `docker-compose.yml` 文件所在的目录执行 `docker-compose up -d --scale kafka=2` 就会在本机启动一个有两个节点的
Kafka 集群:

```shell
➜  Kafka git:(master) docker-compose up -d --scale kafka=2
Creating network "kafka_default" with the default driver
Creating kafka_kafka_1     ... done
Creating kafka_kafka_2     ... done
Creating kafka_zookeeper_1 ... done
➜  Kafka git:(master) docker ps
CONTAINER ID        IMAGE                    COMMAND                  CREATED                  STATUS              PORTS                                                NAMES
d5927ffbd582        wurstmeister/kafka       "start-kafka.sh"         Less than a second ago   Up 6 seconds        0.0.0.0:32774->9092/tcp                              kafka_kafka_2
17916afee832        wurstmeister/zookeeper   "/bin/sh -c '/usr/sb…"   Less than a second ago   Up 7 seconds        22/tcp, 2888/tcp, 3888/tcp, 0.0.0.0:2181->2181/tcp   kafka_zookeeper_1
578c02c01fd9        wurstmeister/kafka       "start-kafka.sh"         Less than a second ago   Up 6 seconds        0.0.0.0:32773->9092/tcp                              kafka_kafka_1
```

两个节点的 Kafka 集群已经成功启动, 节点对应的 container 名分别为 `kafka_kafka_1` 和 `kafka_kafka_2`.

## 通过 Cli 工具演示生产和消费消息

Kafka 官方自带了一些 cli 工具, 可以进入到 container 内部去访问这些命令:

```shell
➜  Kafka git:(master) docker exec -it kafka_kafka_1 bash
bash-4.4# $KAFKA_HOME/bin/kafka-topics.sh --describe --zookeeper kafka_zookeeper_1:2181
Topic:test      PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: test     Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001
```

上面的命令列出了当前 Kafka 集群的所有 Topic.

我自己更喜欢直接在宿主机访问 Kafka 集群, 这就需要先安装上 kafka , 在 macOS 中可以通过 `brew install kafka` 来安装.

安装完成后的使用方法和上面类似, 如列出所有 topic :

```shell
➜  Kafka git:(master) kafka-topics --describe --zookeeper localhost:2181
Topic:test      PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: test     Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001
```

接下来我们来演示如何生产与消费消息.

**创建一个新的 Topic:**

```shell
➜  Kafka git:(master) kafka-topics --create --topic chat --partitions 3 --zookeeper localhost:2181 --replication-factor 2
Created topic "chat".
```

新创建的 Topic 名字为 chat, partition 数为 3, replica 数为 2. 可以通过下面的命令验证 Topic 是否成功创建:

```shell
➜  Kafka git:(master) kafka-topics --describe --zookeeper localhost:2181
Topic:chat      PartitionCount:3        ReplicationFactor:2     Configs:
        Topic: chat     Partition: 0    Leader: 1001    Replicas: 1001,1002     Isr: 1001,1002
        Topic: chat     Partition: 1    Leader: 1002    Replicas: 1002,1001     Isr: 1002,1001
        Topic: chat     Partition: 2    Leader: 1001    Replicas: 1001,1002     Isr: 1001,1002
Topic:test      PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: test     Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001
```

**创建生产者和消费者进程**

消息的生产和消费都需要知道对应的 Broker 地址, 如果在 docker 宿主机上访问的话就需要知道对应的映射端口.
我们可以通过下面的命令获取:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1525811302856.png" width="527"/>

然后通过下面的命令分别去创建消息生产者和消费者:

```shell
kafka-console-producer --broker-list localhost:32773 --topic chat
kafka-console-consumer --bootstrap-server localhost:32773 --topic chat --from-beginning
```

在生产者中输入消息, 就可以在消费者中看到对应的消息输出了, 效果如下图所示:

![](kafka_cli.gif)

可以通过 `<Ctrl-c>` 来退出这两个进程.

# 文件存储原理介绍

我们先回顾下前面关于 Topic chat 的一些信息:

```txt
Topic:chat      PartitionCount:3        ReplicationFactor:2     Configs:
        Topic: chat     Partition: 0    Leader: 1001    Replicas: 1001,1002     Isr: 1001,1002
        Topic: chat     Partition: 1    Leader: 1002    Replicas: 1002,1001     Isr: 1002,1001
        Topic: chat     Partition: 2    Leader: 1001    Replicas: 1001,1002     Isr: 1001,1002
```

从上面可以看出 ID 为 1001 的节点 (kafka_kafka_1) 存储了 Partition 0 和 Partitiont 2 的 Leader 部分,
同时也存储了 Partition 1 的一个备份.

**Partition 是按照下面的算法分布到多个 Kafka 节点:**

* 将所有 N 个 Broker 和待分配的 M 个Partition排序;
* 将第 i 个 Partition 分配到第 (i mod N) 个Broker上;
* 将第 i 个 Partition 的第 j 个副本分配到第 ((i + j) mod N) 个Broker上.

**接下来我们看一看 Partition 具体是怎么存储的**

我们可以登录到节点 1001 内部看下对应的文件存储:

```shell
➜  blog git:(hexo) ✗ docker exec -it kafka_kafka_1 bash
bash-4.4# cd /kafka/kafka-logs-578c02c01fd9/
bash-4.4# ls -d chat*
chat-0  chat-1  chat-2
```

可以看到每一个 Partition 都是和一个目录对应的, 同时每一个目录里都包含了一个 index 文件和 log 文件:

```shell
bash-4.4# ls -lh chat-0
total 16
-rw-r--r--    1 root     root       10.0M May  8 20:52 00000000000000000000.index
-rw-r--r--    1 root     root          77 May  8 20:35 00000000000000000000.log
-rw-r--r--    1 root     root       10.0M May  8 20:52 00000000000000000000.timeindex
-rw-r--r--    1 root     root          10 May  8 20:52 00000000000000000001.snapshot
-rw-r--r--    1 root     root           8 May  8 20:35 leader-epoch-checkpoint
```

其中 log 文件存储实际的消息内容, 而和它同名的 index 文件存储消息的索引数据.
log 的文件名存放的是上一个 log 文件中最后一个消息的 offset 值.

**可以按照下面的方法找到指定 offset 对应的消息**

* 首先定位到对应的 segment ; 这个直接根据文件名进行二分查找就可以找到对应的 segement 了;
* 再在 segment 的 index 文件中顺序查找到 offset 在 log 文件中的位置; index 文件会被映射到内存中.

# 总结

Kafka 通过给 Topic 指定多个 Partition, 而各个 Partition 分布在不同的节点上,
这样便能提供比较好的并发能力. 同时, 对于 Partition 还可以指定对应的 Replica 数,
这也极大地提高了数据存储的安全性, 防止出现数据丢失.

基于文件名去辅助定位消息的设计还是很巧妙的!

最开始计划写本文时是想通过设计一个聊天的场景来讲解的, 发送者是消息生产者,
接受者是消息的消费者, 对于每个用户都去生成一个对应的 Topic.
后来觉得工作量有些略大, 就放弃了. 或许想学习 Go 的 Kafaka SDK
[sarama](https://godoc.org/github.com/Shopify/sarama) 的时候就会去实现这个示例.

# 参考文献

- [Kafka 学习笔记（一） ：为什么需要 Kafka？](https://scala.cool/2018/03/learning-kafka-1/)
- [Kafka快速入门](http://colobu.com/2014/08/06/kafka-quickstart/)
- [Kafka文件存储机制那些事](https://tech.meituan.com/kafka-fs-design-theory.html)
