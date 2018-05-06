---
title: 「Git」底层存储原理详解
date: 2018-03-28 10:46:04
toc: true
categories: Git
tags:
    - Git
---

本文尝试通过一个示例去详细介绍 git 的底层存储的实现原理.

<!--more-->

# 存储原理介绍

Git 的底层存储从本质上讲是基于本地文件系统实现的 Key-Value 数据库.
这里的 Value 是 git 里的三种不同的对象的内容, 而 Key 则是对象内容的 hash 值.

Git 把 Key 存储为目录加文件名 (hash 值的前两位为目录名, 剩余部分作为文件名),
Value 则被存储为文件内容, 默认使用了 zlib 进行压缩. 把 Key 的一部分存储为目录是为了加快文件的定位,
在查找文件时先找到对应的目录, 再遍历目录中的文件进行查找.

## 三种不同对象类型

Git 中有 commit, tree, blob 三种不同的对象. 其中:

* commit 对象存储 git 中的提交信息;
* tree 对象存储 git 仓库中的文件元数据信息, 包括文件名及目录结构信息等;
* blob 则对应的是 git 仓库中的文件内容;

三种不同的对象可以借用 go 语言的 struct 来描述他们的结构, 这里我们其实可以把 Key 看作是一种指针:

```go
// commit object
struct Commit {
   Parent []*Commit
   RootTree *Tree
   Author People
   Committer People
   Message string
}
struct People {
   Name string
   Email string
   Timestamp time.Time
}

// tree object
struct Tree {
   Files []FileMeta
   SubDirs []*Tree
}
struct FileMeta {
   Name string
   FileData *Blob
}

// blob object
struct Blob {
   data []byte
}
```

以上是对 git 底层存储结构的介绍, 还是很简单的, 下面我们以一个例子来详细介绍具体的工作原理.

# 示例解析

创建目录 GitInternal 并执行 `git init`, 添加文件 a.txt :

```sh
➜  GitInternal git:(master) ✗ echo 'file a' > a.txt
```

执行 `git add a.txt`, 这时我们就可以在 `.git/objects` 中看到下面的目录结构:

```sh
➜  objects git:(master) tree
.
├── 4e
│   └── f30bbfe26431a69c3820d3a683df54d688f2ec
├── info
└── pack
```

通过 git 的底层命令查看这个新产生的文件:

```sh
➜  objects git:(master) git cat-file -p 4ef30bbfe26431a69c3820d3a683df54d688f2ec
file a
```

通过 `git commit` 新建一个 commit 之后, 我们再查看下 commit 对象的内容:

```sh
➜  GitInternal git:(master) ✗ git commit -m 'first commit'
[master (root-commit) 0e79428] first commit
 1 file changed, 1 insertion(+)
 create mode 100644 a.txt
➜  GitInternal git:(master) git cat-file -p 0e79428
tree 63bbf0e0280e60aec833588c654ced607189db7e
author Hongbo Liu <hbliu@freewheel.tv> 1522355183 -0400
committer Hongbo Liu <hbliu@freewheel.tv> 1522355183 -0400

first commit
```

因为是第一个 commit, 所以没有 parent commit. 这时我们可以查看下 tree 对象的内容:

```sh
➜  GitInternal git:(master) git cat-file -p 63bbf0e0280e60aec833588c654ced607189db7e
100644 blob 4ef30bbfe26431a69c3820d3a683df54d688f2ec    a.txt
```

这时我们再查看 `.git/objects` 目录下的内容, 会发现和上面提到的三个对象是一一对应的:

```sh
➜  objects git:(master) tree
.
├── 0e
│   └── 794285e05b7ca9f51afb77ace3aed310dc12dc
├── 4e
│   └── f30bbfe26431a69c3820d3a683df54d688f2ec
├── 63
│   └── bbf0e0280e60aec833588c654ced607189db7e
├── info
└── pack
```

## pack 文件

在原始的 git 存储模型中, 我们可以把 commit 看作是仓库在某个时间点的一个快照.
对于每一次修改, 我们都保存的是文件的完整内容, 而不是 diff. 例如当我们修改文件 `a.txt`
再重新提交之后:

```sh
➜  GitInternal git:(master) echo 'append' >> a.txt
➜  GitInternal git:(master) ✗ git commit -am 'append a.txt'
[master 2b5a159] append a.txt
 1 file changed, 1 insertion(+)
```

我们可以看到修改后的文件是被完整地保存为一个 blob 文件的:

```sh
➜  GitInternal git:(master) git cat-file -p 2b5a159
tree 454e5d08e9d43d159488f9d22664cabb31c25dd1
parent 0e794285e05b7ca9f51afb77ace3aed310dc12dc
author Hongbo Liu <hbliu@freewheel.tv> 1522356108 -0400
committer Hongbo Liu <hbliu@freewheel.tv> 1522356108 -0400

append a.txt
➜  GitInternal git:(master) git cat-file -p 454e5d08e9d43d159488f9d22664cabb31c25dd1
100644 blob 5d17781b0c79efe46af70749fe6d6bc14bc11854    a.txt
➜  GitInternal git:(master) git cat-file -p 5d17781b0c79efe46af70749fe6d6bc14bc11854
file a
append
```

同时原来的对象文件也都存在:

```sh
➜  objects git:(master) tree
.
├── 0e
│   └── 794285e05b7ca9f51afb77ace3aed310dc12dc
├── 2b
│   └── 5a1590b3fb9727000e0265dd8d14d07fad8578
├── 45
│   └── 4e5d08e9d43d159488f9d22664cabb31c25dd1
├── 4e
│   └── f30bbfe26431a69c3820d3a683df54d688f2ec
├── 5d
│   └── 17781b0c79efe46af70749fe6d6bc14bc11854
├── 63
│   └── bbf0e0280e60aec833588c654ced607189db7e
├── info
└── pack

8 directories, 6 files
```

如果每修改一次文件都要保存完整的一份, 存储空间利用率会变得很低, git 仓库的大小也会很快增大到不可忍受的地步.
对此, git 的解决方案是定期或者在特定条件下 (例如 push 的时候) 对对象文件进行打包处理.

打包的时候, git 会查找命名及大小相近的文件, 然后保存最新的文件的完整内容,
历史文件则按照 diff 的方式进行保存.

我们可以通过 `git gc` 来手动触发打包过程以观察它的工作机制:

```sh
➜  objects git:(master) git gc
Counting objects: 6, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (6/6), done.
Total 6 (delta 0), reused 0 (delta 0)
➜  objects git:(master) tree
.
├── info
│   └── packs
└── pack
    ├── pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.idx
    └── pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.pack
```

可以看到执行完 `git gc` 之后, 原来的 blob 文件都不存在了, 但在 pack 目录里生成了两个新的文件.
其中 `.pack` 后缀文件存储的是打包前对象文件的实际内容, 而 `.idx` 后缀文件存储的是
各对象文件在 `.pack` 文件中的 index 值.

我们可以通过下面的命令来查看 pack 文件中包含的对象文件内容:

```sh
➜  pack git:(master) git verify-pack pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.idx -v
2b5a1590b3fb9727000e0265dd8d14d07fad8578 commit 223 156 12
0e794285e05b7ca9f51afb77ace3aed310dc12dc commit 175 124 168
5d17781b0c79efe46af70749fe6d6bc14bc11854 blob   14 23 292
454e5d08e9d43d159488f9d22664cabb31c25dd1 tree   33 43 315
63bbf0e0280e60aec833588c654ced607189db7e tree   33 44 358
4ef30bbfe26431a69c3820d3a683df54d688f2ec blob   7 16 402
non delta: 6 objects
pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.pack: ok
```

其中 `git verify-pack -v` 命令的输出格式为:

* 存储原始文件的对象:
```txt
SHA-1 type size size-in-packfile offset-in-packfile
```
* 存储增量的对象:
```txt
SHA-1 type size size-in-packfile offset-in-packfile depth base-SHA-1
```

## 包含子目录的示例

我们在 git 库中添加子目录 `b`, 并新加一个文件 `b.txt` :

```sh
➜  GitInternal git:(master) mkdir b
➜  GitInternal git:(master) echo 'file b' > b/b.txt
➜  GitInternal git:(master) git add ./b
➜  GitInternal git:(master) ✗ git commit -m 'add file b.txt'
[master b6651f8] add file b.txt
 1 file changed, 1 insertion(+)
 create mode 100644 b/b.txt
```

我们查看最新的 tree 对象:

```sh
➜  GitInternal git:(master) git cat-file -p b6651f8
tree 261f921efbc41b76638aa70a63b6eca554eddf72
parent 2b5a1590b3fb9727000e0265dd8d14d07fad8578
author Hongbo Liu <hbliu@freewheel.tv> 1522359722 -0400
committer Hongbo Liu <hbliu@freewheel.tv> 1522359722 -0400

add file b.txt
➜  GitInternal git:(master) git cat-file -p 261f921efbc41b76638aa70a63b6eca554eddf72
100644 blob 5d17781b0c79efe46af70749fe6d6bc14bc11854    a.txt
040000 tree f2996a3c25d2f25ba05bfc4575674774e364e453    b
```

可以发现多了一个子 tree 对象, 再查看它的内容:

```sh
➜  GitInternal git:(master) git cat-file -p f2996a3c25d2f25ba05bfc4575674774e364e453
100644 blob 4f2e6529203aa6d44b5af6e3292c837ceda003f9    b.txt
```

在 `.git/objects` 也包含这些对象对应的文件:

```sh
.
├── 26
│   └── 1f921efbc41b76638aa70a63b6eca554eddf72
├── 4f
│   └── 2e6529203aa6d44b5af6e3292c837ceda003f9
├── b6
│   └── 651f8c1101960af8192d020c0a23f124cfceca
├── f2
│   └── 996a3c25d2f25ba05bfc4575674774e364e453
├── info
│   └── packs
└── pack
    ├── pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.idx
    └── pack-37b85c52cfde7fad12039f5befbc7c23973a43e2.pack

6 directories, 7 files
```

# References

* [GitPro](https://git-scm.com/book/zh/v2/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E5%BA%95%E5%B1%82%E5%91%BD%E4%BB%A4%E5%92%8C%E9%AB%98%E5%B1%82%E5%91%BD%E4%BB%A4)
* [git内部原理](https://www.bittiger.io/blog/post/ExHBZfCRtGwhoYk5f)
* [git-verify-pack](https://git-scm.com/docs/git-verify-pack)
* [Git Internals](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)
