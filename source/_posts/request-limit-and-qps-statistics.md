---
title: 用 go 实现简易版的请求限流和流量统计
date: 2018-05-04 00:03:49
toc: true
categories: Go
tags:
    - Go
---

最近项目需要用到限流和统计流量的功能, 便用 go 基于计数器的原理简单地实现了这两个功能.

<!--more-->

# 限流

限流的要求是在指定的时间间隔内, server 最多只能服务指定数量的请求.
实现的原理是我们启动一个计数器, 每次服务请求会把计数器加一, 同时到达指定的时间间隔后会把计数器清零;
这个计数器的实现代码如下所示:

```go
type RequestLimitService struct {
	Interval time.Duration
	MaxCount int
	Lock     sync.Mutex
	ReqCount int
}

func NewRequestLimitService(interval time.Duration, maxCnt int) *RequestLimitService {
	reqLimit := &RequestLimitService{
		Interval: interval,
		MaxCount: maxCnt,
	}

	go func() {
		ticker := time.NewTicker(interval)
		for {
			<-ticker.C
			reqLimit.Lock.Lock()
			fmt.Println("Reset Count...")
			reqLimit.ReqCount = 0
			reqLimit.Lock.Unlock()
		}
	}()

	return reqLimit
}

func (reqLimit *RequestLimitService) Increase() {
	reqLimit.Lock.Lock()
	defer reqLimit.Lock.Unlock()

	reqLimit.ReqCount += 1
}

func (reqLimit *RequestLimitService) IsAvailable() bool {
	reqLimit.Lock.Lock()
	defer reqLimit.Lock.Unlock()

	return reqLimit.ReqCount < reqLimit.MaxCount
}
```

在服务请求的时候, 我们会对当前计数器和阈值进行比较, 只有未超过阈值时才进行服务:

```go
var RequestLimit = NewRequestLimitService(10 * time.Second, 5)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	if RequestLimit.IsAvailable() {
		RequestLimit.Increase()
		fmt.Println(RequestLimit.ReqCount)
		io.WriteString(w, "Hello world!\n")
	} else {
		fmt.Println("Reach request limiting!")
		io.WriteString(w, "Reach request limit!\n")
	}
}

func main() {
	fmt.Println("Server Started!")
	http.HandleFunc("/", helloHandler)
	http.ListenAndServe(":8000", nil)
}
```

完整的代码放在了 [Github](https://github.com/hiberabyss/JustDoIt/blob/master/RequestLimit/request_limit.go) 上.

## 功能测试

在代码中我们的默认设定是在 10 秒钟内最多只服务 5 个请求. 我们可以每次并行发送 3 个请求看返回结果:

```shell
➜  JustDoIt git:(master) seq 3 | xargs -P10 -I% curl localhost:8000
Hello world!
Hello world!
Hello world!
➜  JustDoIt git:(master) seq 3 | xargs -P10 -I% curl localhost:8000
Hello world!
Hello world!
Reach request limit!
```

可以看到发送到第 6 个请求时就触发了限流操作, 和我们预期的行为是一致的.

# 流量统计

流量统计的实现原理也是类似, 先启动一个计数器, 每次请求都会把计数器加一, 同时再启动一个定时器,
每隔一秒就会把当前计数器的值保存下来, 然后再把计数器清零. 代码如下:

```go
var QPS []CountQPS

type CountQPS struct {
	CountPerSecond int
	Timestamp      int64
}

type CounterService struct {
	CountQPS
	CountAll       int
	Lock           sync.Mutex
}

func NewCounterService() *CounterService {
	counter := &CounterService{}
	go func() {
		ticker := time.NewTicker(time.Second)
		for {
			<-ticker.C
			counter.Lock.Lock()
			counter.Timestamp = time.Now().Unix()

			if counter.CountPerSecond > 0 {
				QPS = append(QPS, CountQPS{counter.CountPerSecond, counter.Timestamp})
			}

			counter.CountPerSecond = 0

			counter.Lock.Unlock()
		}
	}()
	return counter
}

func (counter *CounterService) Increase() {
	counter.Lock.Lock()
	defer counter.Lock.Unlock()

	counter.CountAll++
	counter.CountPerSecond++
}
```

完整的代码保存在 [Github](https://github.com/hiberabyss/JustDoIt/blob/master/QPSstatic/QPS_static.go) 上.

在上面的代码中我们只是把每秒的统计值保存在一个 slice 中, 在实际的项目时间中我们可以把这个信息保存在 influxdb 
这样的数据库或者 Kafka 中.

## 功能测试

在上面的完整代码中我们还实现了一个 `get_cnt` 的 api , 通过它可以打印出当前的所有流量统计值.
让我们来先发送一些请求, 然后看结果是否符合预期:

```shell
➜  JustDoIt git:(master) seq 2 | xargs -P10 -I% curl localhost:8000
Hello world!
Hello world!
➜  JustDoIt git:(master) seq 5 | xargs -P10 -I% curl localhost:8000
Hello world!
Hello world!
Hello world!
Hello world!
Hello world!
➜  JustDoIt git:(master) curl localhost:8000/get_cnt
timestamp,query_per_second
1525496731,2
1525496734,5
total: 7
```

可以看到这个结果也是符合预期的!

# 总结

本文给出的限流和流量统计的方法是比较简单基础的实现, 在某些情况下会有问题, 如参考文献中提到的在限流时间间隔的特定时间点
发送请, 可能会导致实际流量是设计限制流量的两倍. 但本文的方法用在 demo 类的项目中应该也是没什么问题的 :)

欢迎大家多多留言交流!

# 参考链接

- [接口限流算法总结](http://www.kissyu.org/2016/08/13/%E9%99%90%E6%B5%81%E7%AE%97%E6%B3%95%E6%80%BB%E7%BB%93/)
