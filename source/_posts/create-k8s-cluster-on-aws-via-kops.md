---
title: 利用 kops 在 AWS 上创建 K8S 集群
date: 2018-02-02 14:25:55
toc: true
tags:
    - kops
    - AWS
    - K8S
---

本文会介绍 kops 安装及使用, 如何创建 K8S 集群, 以及可能遇到的问题和解决方案.

<!--more-->

# kops 的安装

[kops](https://github.com/kubernetes/kops) 是一个帮助在 AWS, Google Cloud 
等云平台上创建 K8S 集群的工具. 可以通过如下命令安装:

```sh
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
```

# 使用 kops 创建 K8S 集群

## 创建 cluster

执行下面的命令:

```sh
export NETWORKING="flannel"
export CLUSTER_NAME=your-cluster-name.k8s.local
export VPC_ID=vpc-you-vpc-id

# need to create corresponding s3 bucket at first 
export KOPS_STATE_STORE=s3://your-s3 bucket
export ZONES="us-east-1c"

kops create cluster --zones=$ZONES --name=$CLUSTER_NAME \
                    --vpc=${VPC_ID} --networking ${NETWORKING} \
                    --node-count 1 --node-size t2.medium  --master-count 1 \
                    --api-loadbalancer-type=internal --dns private \
                    --master-size t2.medium --topology private --image ami-your-image-id
```

## 修改 subnets

当通过上面的命令创建完 cluster 之后, 我们可能希望 kops 自己去创建 subnet , 而是使用我们
提前配置好的 subnet, 我们可以通过 `kops edit cluster your-cluster-name.k8s.local` 来编辑 subnets 字段:

```yaml
  subnets:
  - id: subnet-your-id
    name: us-east-1c
    type: Private
    zone: us-east-1c
```

## 启动我们创建的 cluster

我们需要通过 `kops update cluster your-cluster-name.k8s.local --yes` 来启动刚刚创建的 cluster.

这个步骤需要下面的 AWS 权限:

```txt
AmazonEC2FullAccess
IAMFullAccess
AmazonS3FullAccess
AmazonVPCFullAccess
```

我们可以通过有这些权限的账号来执行上面的命令, 或者在拥有这些权限的 EC2 (通过 IAM Role)
上执行.

# 如何解决问题

当执行完上面的步骤之后应该就可以成功地在 AWS 上创建一个 K8S 集群. 可以通过以下步骤去检查问题出现在哪里:

## 检查 EC2 instances 有没有被成功创建

如果没有对应的 EC2 被创建, 我们需要去 Auto Scaling Groups 里检查对应 Activity History :

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1517554624176.png" width="518"/>

可能的原因有:

1. AMI image 需要被 Accepted;
2. 没有可用的 Volume ;

## EC2 成功创建但没法被 K8S 集群识别

这种情况一般是启动的 EC2 上的 `kubelet` 或 `kube-apiserver` 未被成功启动.

### master 节点未被成功识别
如果 master 无法被正常识别, 我们可以取检查 Load Balancer (LB) 是不是有 instance 且状态是不是 `InService`:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1517554976973.png" width="878"/>

这个 LB 是通过检查 443 端口(一般是 kube-apiserver) 来判定服务是不是 InService , 如果这儿有问题, 一般是因为 `kube-apiserver`
未正常启动

### node 节点未被识别

这种情况一般是 docker service 或者 kubelet 未被成功启动, 需要登录到对应的机器去检查原因.
可能的情况是 node 节点无法访问外网, 导致无法安装 kubelet 的包.
