---
title: 「C++」typeid 介绍
date: 2021-02-09 11:32:06
toc: true
mathjax: true
categories:
tags:
    - c++
---

`typeid` 是 c++ 中的一个关键字，它和 `sizeof` 类似，它是一个运算符，能获取到 c++ 的类型信息。

`typeid` 能够对多态对象在运行时获取其真实的类型信息。

<!--more-->

# typeid 使用方式

typeid 有两种使用方式：

* `typeid(type)` 例如 `typeid(int)`
* `typeid(expression)` 例如 `typeid(variable_name)`

typeid 会返回一个 `std::type_info` 类型，它的定义如下所示：

```cpp
class type_info {
public:
  const char* name() const;  // 名称是按照编译器自己的命名体系来返回，不同类的 name 不同
  bool operator==(const type_info& rhs) const;
  bool operator!=(const type_info& rhs) const;
  bool before(const type_info& rhs) const;  // 类型内部定义时的实现顺序，不同编译器可能不一样
}
```

# 编译时或运行时判定

如果对象没有多态性质的话，可以在编译时期就决定它的对象类型：

```cpp
class Point {
  private:
    int x_;
}

class Point2D : public Point {
  private:
    int y_;
}

int main() {
  Point* p = new Point2D();
  assert(typid(*p) == typeid(Point));
}
```

对于存在多态的类型，会在运行时判定：

```cpp
class Point {
  virtual ~Point();

  private:
    int x_;
}

class Point2D : public Point {
  private:
    int y_;
}

int main() {
  Point* p = new Point2D();
  assert(typid(*p) == typeid(Point2D));
}
```
