---
title: 编程语言中的闭包
date: 2018-03-06 16:11:13
toc: true
tags:
    - Programming
---

闭包是现代的高级编程语言的一个重要概念, 本文会以 Golang 为例来介绍什么是闭包.

<!--more-->

# 什么是闭包 (Closure)

在介绍闭包的定义之前, 我们先来看下闭包的示例代码:

```go
package main

import "fmt"

func greeting(name string) func() string {
	data := "Hello " + name
	return func() string { return data }
}

func main() {
	sayHi := greeting("hbliu")
	fmt.Println(sayHi())
}

// result:
// Hello hbliu
```

这段代码就实现了闭包的效果: 虽然 `greating` 函数已经返回了, 但我们还可以访问到其内部的
`data` 局部变量. 下面是 [CoolShell][CoolShell] 对闭包的定义:

- 闭包就是函数的局部变量集合，只是这些局部变量在函数返回后会继续存在。
- 闭包就是就是函数的“堆栈”在函数返回后并不释放，我们也可以理解为这些函数堆栈并不在栈上分配而是在堆上分配
- 当在一个函数内定义另外一个函数就会产生闭包

在[文章][segment]中给了另外一个定义: 闭包是指有权访问另一个函数作用域中的变量的函数

访问函数内局部变量一般都是通过返回使用了函数局部变量的内部函数来实现的.
由此可见, 为了支持闭包, 编程语言需要提供一下两个特性:

* 函数是 First Class Value, 即函数可以作为另一个函数的返回值或参数;
* 函数可以嵌套定义, 即可以在一个函数内部定义另外一个函数

闭包和对象都是既有函数也有数据, 可以用一句话来表明他们的区别:
**对象是附有行为的数据，而闭包是附有数据的行为**

# 闭包的优缺点

## 优点

1. 闭包可以减少全局变量的个数;
2. 保存闭包外面的变量状态; 下面是一个示例:

下面的代买要用 goroutine 来打印一个 slice.  使用闭包前:

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	wg.Add(2)

	arr := []int{2, 3}
	for _, n := range arr {
        go func() {
            defer wg.Done()
            fmt.Println(n)
        }()
	}

	wg.Wait()
}

// resutl:
// 3
// 3
```

可以发现结果都是 3 , 这是因为 goroutine 用的都是同一个变量 `n`.

我们可以使用闭包来避免这个问题:

```go
// Package main provides ...
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	wg.Add(2)

	arr := []int{2, 3}
	for _, n := range arr {
		func() {
			backup := n
			go func() {
				defer wg.Done()
				fmt.Println(backup)
			}()
		}()
	}

	wg.Wait()
}

// result:
// 3
// 2
```

## 缺点

闭包的缺点就是常驻内存，会增大内存使用量，使用不当很容易造成内存泄露。

# References

- [理解JAVASCRIPT的闭包](https://coolshell.cn/articles/6731.html)
- [闭包的概念、形式与应用](https://www.ibm.com/developerworks/cn/linux/l-cn-closure/#note_1)
- [函数闭包的优势和特点](https://pengweifu.github.io/2014/11/22/Js-Closure.html)
- [详解js闭包][segment]

[segment]: https://segmentfault.com/a/1190000000652891
[CoolShell]: https://coolshell.cn/articles/6731.html
