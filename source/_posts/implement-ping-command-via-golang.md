---
title: 使用 golang 实现 ping 命令
date: 2018-03-12 16:27:35
toc: true
categories:
tags:
    - go
---

ping 是一个经常被用来检查主机间连通性的工具, 它基于 ICMP 协议实现,
基本原理很简单: 本机给远程机器发送 ICMP 报文, 远程主机接收到 ICMP 报文后便会回复一个类似的 ICMP 报文;
当本机接收到回复后变认为远程主机是可连接的, 否则便认为这个主机是不可达的.

为了了解 golang 的网络编程, 我用 go 实现了一个 ping 命令, 本文会介绍如何实现 ping 命令.

<!--more-->

# Demo

[这里有完整的示例代码](https://github.com/hiberabyss/JustDoIt/tree/master/ping),
可以直接执行实现下面的效果 (**注意需要 sudo 权限**):

```shell
➜  ping git:(master) sudo go run goping.go baidu.com
Ping 111.13.101.208 (baidu.com):

28 bytes from 111.13.101.208: seq=1 time=9ms
28 bytes from 111.13.101.208: seq=2 time=9ms
28 bytes from 111.13.101.208: seq=3 time=10ms
28 bytes from 111.13.101.208: seq=4 time=10ms
28 bytes from 111.13.101.208: seq=5 time=9ms
```

# 如何实现

## ICMP 报文

首先我们需要定义出 ICMP 报文头的结构:

```go
type ICMP struct {
	Type        uint8
	Code        uint8
	CheckSum    uint16
	Identifier  uint16
	SequenceNum uint16
```

其中 `Type` 表明的是 ICMP 的类型, `Code` 则用来进一步划分 ICMP 的类型, ping
使用的是 echo 类型的 ICMP, 这两个值需要分别设置为 8 和 0.

`CheckSum` 是报文头的校验值, 以防止在网络传输过程中的数据错误. 会先把这个字段设置为 0 来计算校验值,
计算完成后再把校验值赋值到这个字段.

ID 是用来标识一个 ICMP, 可以设置为 0; 而 `SequenceNum` 则是序列号, 可以在发送 ICMP 报文的时候依次累加.

[这篇文章][icmp]对 ICMP 的结构有更详细的介绍.

基于上面的描述, 我们可以实现下面这个基于序列号生成 ICMP 报文头的函数:

```go
func getICMP(seq uint16) ICMP {
	icmp := ICMP{
		Type:        8,
		Code:        0,
		CheckSum:    0,
		Identifier:  0,
		SequenceNum: seq,
	}

	var buffer bytes.Buffer
	binary.Write(&buffer, binary.BigEndian, icmp)
	icmp.CheckSum = CheckSum(buffer.Bytes())
	buffer.Reset()

	return icmp
}
```

其中 `CheckSum()` 是用来计算校验值的函数. 在网络中传输的数据需要是大端字节序的.

## 发送及接收 ICMP 报文

首先, 我们使用 `net.DialIP("ip4:icmp", nil, destAddr)` 来创建一个 ICMP 报文.

接着我们使用下面的代码填充 ICMP 报文并发送:

```go
binary.Write(&buffer, binary.BigEndian, icmp)

if _, err := conn.Write(buffer.Bytes()); err != nil {
    return err
}
```

发送完之后, 我们使用下面的命令接收请求:

```go
recv := make([]byte, 1024)
receiveCnt, err := conn.Read(recv)
```

同时我们还需要统计发送到接收之间所耗费的时间.

完整的代码如下所示:

```go
func sendICMPRequest(icmp ICMP, destAddr *net.IPAddr) error {
	conn, err := net.DialIP("ip4:icmp", nil, destAddr)
	if err != nil {
		fmt.Printf("Fail to connect to remote host: %s\n", err)
		return err
	}
	defer conn.Close()

	var buffer bytes.Buffer
	binary.Write(&buffer, binary.BigEndian, icmp)

	if _, err := conn.Write(buffer.Bytes()); err != nil {
		return err
	}

	tStart := time.Now()

	conn.SetReadDeadline((time.Now().Add(time.Second * 2)))

	recv := make([]byte, 1024)
	receiveCnt, err := conn.Read(recv)

	if err != nil {
		return err
	}

	tEnd := time.Now()
	duration := tEnd.Sub(tStart).Nanoseconds() / 1e6

	fmt.Printf("%d bytes from %s: seq=%d time=%dms\n", receiveCnt, destAddr.String(), icmp.SequenceNum, duration)

	return err
}
```

# ping 命令的完整代码

[Github 上的文件路径](https://github.com/hiberabyss/JustDoIt/blob/master/ping/goping.go)

```go
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"net"
	"os"
	"time"
)

type ICMP struct {
	Type        uint8
	Code        uint8
	CheckSum    uint16
	Identifier  uint16
	SequenceNum uint16
}

func usage() {
	msg := `
Need to run as root!

Usage:
	goping host

	Example: ./goping www.baidu.com`

	fmt.Println(msg)
	os.Exit(0)
}

func getICMP(seq uint16) ICMP {
	icmp := ICMP{
		Type:        8,
		Code:        0,
		CheckSum:    0,
		Identifier:  0,
		SequenceNum: seq,
	}

	var buffer bytes.Buffer
	binary.Write(&buffer, binary.BigEndian, icmp)
	icmp.CheckSum = CheckSum(buffer.Bytes())
	buffer.Reset()

	return icmp
}

func sendICMPRequest(icmp ICMP, destAddr *net.IPAddr) error {
	conn, err := net.DialIP("ip4:icmp", nil, destAddr)
	if err != nil {
		fmt.Printf("Fail to connect to remote host: %s\n", err)
		return err
	}
	defer conn.Close()

	var buffer bytes.Buffer
	binary.Write(&buffer, binary.BigEndian, icmp)

	if _, err := conn.Write(buffer.Bytes()); err != nil {
		return err
	}

	tStart := time.Now()

	conn.SetReadDeadline((time.Now().Add(time.Second * 2)))

	recv := make([]byte, 1024)
	receiveCnt, err := conn.Read(recv)

	if err != nil {
		return err
	}

	tEnd := time.Now()
	duration := tEnd.Sub(tStart).Nanoseconds() / 1e6

	fmt.Printf("%d bytes from %s: seq=%d time=%dms\n", receiveCnt, destAddr.String(), icmp.SequenceNum, duration)

	return err
}

func CheckSum(data []byte) uint16 {
	var (
		sum    uint32
		length int = len(data)
		index  int
	)
	for length > 1 {
		sum += uint32(data[index])<<8 + uint32(data[index+1])
		index += 2
		length -= 2
	}
	if length > 0 {
		sum += uint32(data[index])
	}
	sum += (sum >> 16)

	return uint16(^sum)
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}

	host := os.Args[1]
	raddr, err := net.ResolveIPAddr("ip", host)
	if err != nil {
		fmt.Printf("Fail to resolve %s, %s\n", host, err)
		return
	}

	fmt.Printf("Ping %s (%s):\n\n", raddr.String(), host)

	for i := 1; i < 6; i++ {
		if err = sendICMPRequest(getICMP(uint16(i)), raddr); err != nil {
			fmt.Printf("Error: %s\n", err)
		}
		time.Sleep(2 * time.Second)
	}
}
```

# References

* [Golang实现ping][icmp]
* [使用Golang实现简单Ping过程](http://blog.csdn.net/wangkai_123456/article/details/67632901<Paste>)

[icmp]: http://blog.csdn.net/simplelovecs/article/details/51146960
