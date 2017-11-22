---
title: 利用 AWS 的 EBS 为 kubernetes 集群添加持久化存储
date: 2017-11-22 10:21:27
toc: true
tags:
    - AWS
    - Kubernetes
---

本文介绍如何创建一个 EBS 卷，并把这个 EBS 卷挂载到 kubernetes 集群里的 POD 上。

<!--more-->

## 创建一个 EBS 卷

用 `aws configure` 配置好 aws 命令行之后（如果开启了 mfa ，需要先调用下 `eval $(aws-mfa)`），我们便可以调用下面的命令创建一个 EBS 卷：

```shell
aws ec2 create-volume --availability-zone us-east-1a --size 20 --volume-type gp2
```

上面的命令会得到类似下面的输出：

```json
{
    "AvailabilityZone": "us-east-1a",
    "Encrypted": false,
    "VolumeType": "gp2",
    "VolumeId": "vol-123456we7890ilk12",
    "State": "creating",
    "Iops": 100,
    "SnapshotId": "",
    "CreateTime": "2017-01-04T03:53:00.298Z",
    "Size": 20
}
```

记录下 `VolumeId` ，会在后面的步骤中用到。

## 创建 K8S 中的 Persistent Volume (PV)

创建文件 `aws-pv.yaml`：

```yaml
apiVersion: "v1"
kind: "PersistentVolume"
metadata:
  name: "aws-pv" 
  labels:
    type: amazonEBS
spec:
  capacity:
    storage: "10Gi" 
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore: 
    fsType: "ext4" 
    volumeID: "vol-123456we7890ilk12" 
```

利用 kubectl 创建 Persistent Volume ：

```shell
kubectl apply -f aws-pv.yaml
```

可用命令 `kubectl get pv` 来查看创建的 Persistent Volume 的状态：

```txt
NAME       CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS      CLAIM               REASON    AGE
aws-pv     10Gi        RWX           Retain          Available                                7s
```

## 创建 Persistent Volume Claim

创建 Persistent Volume Claim (PVC) 和之前创建的 PV 进行绑定，K8S 中的 POD 通过 PVC
来使用 PV 。

创建文件 `pvc.yaml` ：

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: aws-pvc
  labels:
    type: amazonEBS
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

通过 `kubectl` 创建 PVC ：

```shell
kubectl apply -f pvc.yaml
```

查看创建的 PVC ：

```shell
kubectl get pvc
```

## 在 POD 中使用 PVC

先创建对应 PVC 的 volume ：

```yaml
    volumes:
    - name: data-repa
      persistentVolumeClaim:
        claimName: aws-pvc
```

再添加 mount ：

```yaml
    volumeMounts:
    - name: data-repa
      mountPath: /ads/data/pusher
```

## Some Tips

一个 EBS 最多只能挂在到一台 EC2 上，如果希望多台机器上的 POD 能共享数据，
则需要使用 EFS、NFS 或 GlusterFS。

## References

- [Using Kubernetes Persistent volume to store persistent data](https://blog.bigbinary.com/2017/04/12/using-kubernetes-persistent-volume-for-persistent-data-storage.html)
