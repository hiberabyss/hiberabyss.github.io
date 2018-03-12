---
title: 「tor」基于 Tor Browser 翻墙
date: 2018-03-12 11:43:55
toc: true
categories: VPN
tags:
    - tor
    - vpn
---

由于众所周知的原因, 国外的一些网站无法被访问到. 
但有时偶尔需要访问下这些网站, 我们便可以通过 Tor Browser 来翻墙.

<!--more-->

# Tor Browser 的优缺点

优点:

* 开箱即用, 不需要复杂的配置;
* 稳定且没有流量限制; 不像 Lantern, 有时会很不稳定, 而且每个月还有 500MB 的流量限制;

缺点:

* 速度太慢, 基本也就能刷刷网页了;

# 安装

通过 [Tor Browser官网](https://www.torproject.org/projects/torbrowser.html.en)
下载安装即可 (如无法下载, 可在页面下方评论, 我会提供下载链接).

安装完成打开后, 我们直接选择 `meek-amazon` 或 `meek-azure` 即可, 如下图所示:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520827025220.png" width="548"/>

然后点确定, 最后就会进入下面的页面:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520827101652.png" width="637"/>

这个浏览器默认就可以翻墙了, 默认可以访问 Google, FaceBook 等网站.

# 让 Chrome 也能用上 Tor Browser 的代理

Tor Browser 会在 9150 端口上开启一个 tor 的代理, 当我们打开 Tor Browser 之后,
配置 Chrome 使用这个代理就可以翻墙了. 下图是基于 SwitchyOmega 配置的代理:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520829500960.png" width="855"/>

# 通过 Tor Browser 切换 IP

有些网站会基于 IP 做一些限制, 我们可以很方便的通过 Tor Browser 来切换对外的 IP.
每次当我们点击 "为此站点使用新 Tor 线路" 的时候就会切换成一个新的 IP 地址:

<img src="http://on2hdrotz.bkt.clouddn.com/blog/1520829784387.png" width="428"/>
