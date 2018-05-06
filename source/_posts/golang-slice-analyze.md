---
title: 「Golang」Slice 详解
date: 2018-03-23 16:21:36
toc: true
categories: Go
tags:
    - Go
---

slice 是 go 里面最常用到的数据结构了, 但稍有不慎, 就会踩到一些坑.
本文会对 slice 的原理及使用通过代码的方式做一个总结和梳理.

<!--more-->

# golang 的数组

slice 本质上是基于数组实现的, 为了更好地理解 slice, 我们先介绍下 golang 里的数组.

golang 中的数组和 C 语言中的数组特别类似, 都是定长的同类型数据的集合.
我们可以通过 `[2]int {12, 8}` 来定义一个数组, 也可以通过另外一种形式
`[...]int {12, 8}` 来让编译器自己算出数组的实际长度.

数组的长度是不能被改变的, 我们可以通过 `len(array)` 来获取数组的长度.

数组其实可以看作一种特殊类型的 struct, 例如对于 `[2]int` 可以用类似下面的 struct 表示:

```go
struct array {
  int
  int
}
```

对于这个结构体, 我们可以通过 index 去访问它的成员值, 如 `array[0]` 可以访问到第一个元素.

不同于 C 语言中的数组, golang 中的数组不是指向第一个元素的指针. 当对一个数组进行赋值或者作为参数传递时,
数组会被完全复制一份, 如果把数组理解成一种特殊类型的 struct 的话, 这个行为就很好理解了.

# slice 的本质

slice 可以看作是由三个元素组成的结构体:

```go
struct slice {
  ptr
  len
  cap
}
```

其中 `ptr` 是指向底层数组的指针, len 表示当前 slice 中元素的数量, cap 表示当前底层数组大小.

我们用 make 来创建 slice 的时候, 最多可以指定三个参数:

```go
make([]Type, len, cap)
```

其中第三个参数是可选的, 用于指定底层数组的大小, 如果未指定, 则默认是和第二个参数是一致的.

用 make 创建的指定大小的数组会用类型的 0 值进行初始化, 例如对于下面的代码:

```go
s := make([]int, 2)
s = append(s, 2, 3)
fmt.Println(s)

// Result:
// [0 0 2 3]
```

它的输出结果是 `[0 0 2 3]`, 这是因为用 make 创建 slice 的时候, 里面已经存在了 2 个 0 值元素.

这里需要指出的一点是对 slice 的赋值操作是 O(1) 的, 它和底层数组的大小没有关系,
因为我们只需要把 (ptr, len, cap) 这三个值拷贝到新的 slice 即可.

## 子 slice

我们可以通过 `slice[begin:end:cap_idx]` 来获取一个子 slice, 子 slice 的大小是 `end - begin`,
其中 end 和 cap_idx 最大可以设置为 `cap(slice)`. 子 slice 相当于是:

* ptr = slice.ptr + begin
* len = end - begin
* cap = cap_idx - begin

## slice 容量的自动扩展

当我们往 slice 中 append 数据时, 如果 slice 还有容量时, 直接 `slice[len] = newValue` 即可:

```go
s := make([]int, 0, 2)
_ = append(s, 1, 2)
s1 := s[0:2:2]

fmt.Println(s1)

// Result:
// [1 2]
```

但如果 append 的数据超过当前 slice 的容量时, 便会重新申请一个数组存放要添加的数据.
例如我们往上面例子中的 slice 再添加一个新的数据时, 便会超过之前的容量而去重新申请一个数组.
这样之前数组里的内容便会还是默认值, 输出结果为: `[0 0]`

```go
s := make([]int, 0, 2)
_ = append(s, 1, 2, 3)
s1 := s[0:2:2]

fmt.Println(s1)

// Result:
// [0 0]
```

当对之前的 slice 容量进行扩展时, 每次都是两倍于之前的容量, 我们可以通过下面的代码来进行验证:

```go
func sliceIncreaseExample() {
	s := make([]int, 3)

	cCap := 0

	for i := 0; i < 128; i++ {
		if cap(s) != cCap {
			fmt.Println(len(s), cap(s))
			cCap = cap(s)
		}
		s = append(s, i)
	}
}

// Result:
// 3 3
// 4 6
// 7 12
// 13 24
// 25 48
// 49 96
// 97 192
```

# References

- [Go 切片：用法和本质](https://blog.go-zh.org/go-slices-usage-and-internals)
- [Go语言slice的那些坑](https://studygolang.com/articles/6557)
