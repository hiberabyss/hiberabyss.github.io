---
title: 直接在电脑端获取 AWS 的 MFA code
date: 2017-11-23 20:10:35
toc: true
tags:
    - AWS
    - Alfred
    - macOS
---

当 AWS 开启了 MFA 认证之后，登录时就需要输入应的 MFA code 。
默认我们可以通过手机应用 Google Authenticator 来获取到这个 code ，
登录的过程还需要使用手机是一种很低效的方式，而且有时还会遇到手机不在身边的情况。
本文会介绍两种可以在电脑端获取 MFA code 的方法。

<!--more-->

## 获取 MFA 设备的秘钥

在实现电脑端获取 MFA code 前，我们需要先获取到 MFA device 的秘钥：

1. 切换到 “My Security Credentials” 面板：
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1511439986529.png" width="193"/>

2. 搜索你自己的用户名，并点击进入：
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1511440121929.png" width="565"/> 

3. 切换到 “Security Credentials” tab 页，编辑 “Assigned MFA device”（如果之前有 assign 过 MFA 设备需要先 deactive）：
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1511440283396.png" width="658"/>

4. 一路点 Next ，最后就可以看到 MFA device 的秘钥了：
<img src="http://on2hdrotz.bkt.clouddn.com/blog/1511440632702.png" width="739"/>

## 通过命令行方式获取 MFA code

先安装 [gauth](https://github.com/pcarrier/gauth) 命令：

```shell
go get github.com/pcarrier/gauth
```

编辑文件 `~/.config/gauth.csv`，填入上一步获取的秘钥：

```config
AWS: ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRSTUVWXYZ234567
```

还需要设置好文件的权限： `chmod 600 ~/.config/gauth.csv` 。

执行命令 `gauth` 即可获取如下输出：

```shell
$ gauth
           prev   curr   next
AWS        315306 135387 483601
[=======                      ]
```

其中最后一行表示的是剩余时间。

## 通过 Alfred Workflow 来获取 MFA code

如果安装了 Alfred 并激活了 Powerpack ，可以通过 Alfred Workflow
[Google Authenticator](https://github.com/moul/alfred-workflow-gauth/blob/develop/Google%20Authenticator.alfredworkflow?raw=true)
来实现如下图所示的效果：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1511442187231.png" width="558"/>

我个人更喜欢这种方式，直接按回车键就可以把 MFA code 复制到系统剪贴板。

### 如何安装

1. 下载
[Google Authenticator](https://github.com/moul/alfred-workflow-gauth/blob/develop/Google%20Authenticator.alfredworkflow?raw=true)
并导入到 Alfred；
2. 编辑文件 `~/.gauth` ，填入之前获取的 MFA 设备的秘钥：

```config
[AWS - lhbf@qq.com]
secret = ABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABCDEFGHIJKLMNOPQRSTUVWXYZ234567
```

## References

- https://github.com/pcarrier/gauth
- https://github.com/moul/alfred-workflow-gauth
