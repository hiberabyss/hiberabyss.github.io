---
title: 在 Kubernetes 的多个 Nodes 上执行命令
date: 2017-12-01 11:31:04
toc: true
tags:
    - Kubernetes
    - Fabric
---

有时我们会需要在多个 K8S 的 Nodes 节点上执行一些命令，可以借助工具
[fabric-kubernetes-nodes](https://github.com/coreos/fabric-kubernetes-nodes)
来实现这个目的。

<!--more-->

# 如何使用

fabric-kubernetes-nodes 主要是利用 fabric 工具以及 K8S 的标签系统来实现的。
我们可以通过给想要进行操作的所有节点加上 label，然后通过这个 label 来对他们进行操作：

```yaml
kubectl label node node1 node2 my-special-label=true
fab -u core -R my-special-label=true -- date
```

对于通过 kops 建立的 K8S 集群，我们可以通过下面的命令来对所有的 Node 节点来进行操作：

```sh
export FAB_KUBE_NODE_ADDRESS_TYPE=InternalIP

fab -P --fabfile $HOME/github/fabric-kubernetes-nodes/fabfile.py \
    -R "kubernetes.io/role=node" -- $@
```

把上面的内容保存为 `pnodes` 并加上可执行权限，便可很方便地在所有节点上执行命令：

```sh

➜  blog git:(hexo) ✗ pnodes date
[10.28.12.43] Executing task '<remainder>'
[10.28.2.248] Executing task '<remainder>'
[10.28.8.119] Executing task '<remainder>'
[10.28.8.119] run: date
[10.28.2.248] run: date
[10.28.12.43] run: date
[10.28.12.43] out: Fri Dec 22 02:53:01 UTC 2017
[10.28.12.43] out:

[10.28.8.119] out: Fri Dec 22 02:53:01 UTC 2017
[10.28.8.119] out:

[10.28.2.248] out: Fri Dec 22 02:53:01 UTC 2017
[10.28.2.248] out:
```

## 给 Instance Group(IG) 加上 nodeLable

当通过 kops 创建 k8s 集群时，我们可以通过如下的方式给 IG 加上 label ，
就可以通过这个 label 对整个 IG 进行操作：

```yaml
spec:
  nodeLabels:
    ads: perf
```

