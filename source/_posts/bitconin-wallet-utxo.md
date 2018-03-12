---
title: 比特币交易的原理
date: 2018-03-07 21:04:33
toc: true
categories: BlockChain
tags:
    - blockchain
    - UTXO
---

本文会介绍比特币里的交易是如何发生的, 矿工挖到区块后是如何获取到比特币的,
以及比特币钱包里的余额是什么含义.

<!--more-->

# 比特币钱包

简单来说, 比特币钱包是由 (公钥, 私钥) 对组成的. 可以从私钥 (PrivateKey) 得到公钥 (PublicKey),
但却很难从 PublicKey 推导出 PrivateKey.

在比特币的交易过程中, 我们用 PublicKey 接收比特币 (账户地址); 同时, 只有用这个 PublicKey 对应的 PrivateKey 才能
消费这个地址里的比特币.

和现有的银行卡系统类比的话, PublicKey 相当于是银行卡号, 别人只要知道你的卡号就可以给你转钱;
而 PrivateKey 就相当于银行卡号加密码的组合, 知道它就可以给别人转账.

# 账户系统和 Unspent Transaction Output (UTXO)

我们常用的银行卡是一种账户系统:

* 在系统中记录着每个账户的当前余额;
* 在用户进行转账时, 我们会先检查转账金额是否小于等于当前账户余额, 只有检查通过时交易才能进行;

而比特币使用的是另外一种 UTXO (TX 是 Transaction 的简写) 系统:

* UTXO 中不会保存账户的余额;
* 

# References

- [其实并没有什么比特币，只有 UTXO][utxo]
- [比特币 (Bitcoin) 系统是如何运行的？](https://www.zhihu.com/question/20941124/answer/20411491)
- [How is a wallet's balance computed?](https://bitcoin.stackexchange.com/a/23034)
- [比特币是如何防范双花的?](https://www.zhihu.com/question/39948446/answer/150934017)

[utxo]: http://8btc.com/article-4381-1.html
