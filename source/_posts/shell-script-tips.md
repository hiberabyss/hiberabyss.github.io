---
title: Shell 脚本里遇到的一些坑
date: 2018-05-16 23:21:02
toc: true
categories: Linux
tags:
    - Shell
---

最近在写 Shell 脚本的时候遇到了一些坑, 稍不留意就会踩到,
在这里和大家分享一下.

<!--more-->

# 使用 `>` 或 `<` 等进行数字的大小比较

在 Shell 脚本里有需要对数字进行比较的地方, 发现当数字变为两位数之后结果就会不对.
仔细检查了源代码, 发现是错误地使用了 `>` 进行了数字的比较.
但 `<` 和 `>` 其实都是用于字符串比较, 它会按顺序比较每一个字符的大小.
例如对于如下的代码:

```shell
if [[ 3 > 2  ]]; then echo 'yes'; else echo 'no'; fi
# Output: yes

if [[ 10 > 2  ]]; then echo 'yes'; else echo 'no'; fi
# Output: no
```

可以看到 `10 > 2` 的返回结果是 false , 和我们的预期是不一致的. 这里应该使用 `-gt`
进行比较:

```shell
if [[ 10 -gt 2  ]]; then echo 'yes'; else echo 'no'; fi<Paste>
# Output: yes
```

更多相关资料可以通过 `man test` 查看.

# Shell 脚本里变量的作用域

假设有这样一个需求希望你用 Shell 脚本来实现: 输出五行 `01234`.

你可能很快就会写出下面的代码:

```shell
print_num() {
    for (( i = 0; i < 5; i++ )); do
        echo -n $i
    done
    echo ""
}

print_line() {
    for (( i = 0; i < 5; i++ )); do
        print_num
    done
}

print_line
```

然后当你执行的时候会发现输出结果只有一行 `01234`.

这是为什么呢? 秘密就藏在变量 `i` 里. Shell 脚本里的变量默认都是全局变量,
当我们执行完一次 `print_num` 函数后, `i` 就变成了 5, 因为 `i` 是全局变量,
其值的改变也能反映到函数 `print_line` 里, 当 `print_num` 返回之后, `print_line` 的循环条件也就不满足了.

怎么修复这个问题呢? 我们可以先在 `print_line` 的 for 循环前加上 `local i` 的声明.
发现结果还是一样的, 这说明在函数内部被声明成 `local` 的变量, 在其后续被调用的函数里还是依然可见的.

我们再尝试在 `print_num` 的 for 循环前面加上 `local i` 的声明呢? 这次发现结果是和我们的预期一致的:

```txt
01234
01234
01234
01234
01234
```

上面的例子告诫我们, 在定义变量时, 如果它不是全局变量, 要养成加上 `local` 声明的好习惯!

# 总结

Shell 作为一种脚本语言, 语法检查没有 C++ 之类的编程语言严格, 则虽然可以带来很大的灵活性,
但无形中也增加了犯错的可能性. 本文会不断更新我在编写 Shell 脚本时遇到的坑!
