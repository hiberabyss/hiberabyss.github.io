---
title: 配置 AWS CLI 工具
date: 2018-01-14 23:43:04
toc: true
tags:
	- AWS
    - MFA
---

通过 aws cli 工具我们可以通过脚本来自动化执行很多操作，同时也能很方便地和 S3 进行交互。
本文会介绍如何安装及配置 aws-cli 工具。

# 安装 aws-cli

安装 aws-cli 首先需要安装 python 的 pip 包管理工具，我们可以通过下面的命令安装它：

```sh
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
sudo python get-pip.py
```

成功安装 pip 之后，我们可以很方便地通过 `sudo pip install awscli` 来安装 aws-cli 工具。

# 配置

安装完 aws-cli 之后需要进行配置，主要包括下面三项的配置：

```sh
➜  ~ aws configure
AWS Access Key ID [****************ZPKQ]:
AWS Secret Access Key [****************vN7P]:
Default region name [None]: us-east-1
```

其中 `Access Key ID` 和 `Secret Access Key` 可以从 AWS Console 上的 `My Security Credentials`
页面中获取：

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1515945723095.png" width="722"/>

## Tips

当配置新的机器时，可以直接把之前成功配置的机器上的 `~/.aws` 复制到新机器即可。

# 配合 aws-mfa 命令使用

很多时候为了安全起见，aws 账户会开启 MFA 的认证，这时即使按照上面配置好 aws-cli ，
在执行的时候依然会有访问权限相关的错误：

```sh
➜  ~ aws s3 ls

An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
```

这时我们就需要另外一个工具：aws-mfa

## 安装 aws-mfa

安装 aws-mfa 需要 `gem` 命令，如果不存在这个命令，可以通过 `sudo yum install -y gem` 来安装。

确保 gem 成功安装后，我们便可通过 `gem install aws-mfa` 来安装 aws-mfa 。

## 使用 aws-mfa

它有两种使用方式：

1. 直接在 shell 里执行 `eval $(aws-mfa)`，输入对应的 MFA code:

```sh
➜  ~ eval $(aws-mfa)
Enter the 6-digit code from your MFA device:
051059
```

执行完这个命令后，我们便可在这个 shell 里正常执行 aws 命令了。

2. 我们还可以直接在 aws 命令前加上 aws-mfa 。我个人更喜欢这种方式，可以在 shell rc 文件里配置
`alias aws='aws-mfa aws'` 这样的 alias


