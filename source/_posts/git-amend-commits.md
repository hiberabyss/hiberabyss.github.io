---
title: "Git Tips：修改 commits"
toc: true
date: 2017-03-21 00:03:41
tags:
---
总是会存在这样的场景：在开开心心地用 git commit 提交了代码之后，才发现 commit message 里有 typo，
或者是有些文件忘记 commit 了，又或者是有些垃圾文件被不小心 commit 了；这时不要伤心、不要难过，
因为 git 给你提供了后悔药。

<!--more-->

## 修改最近的一个 commit

如果想要修改最近的一个 commit 的 message，直接执行 `git commit --amend`，然后在编辑器里修改 message 信息，
保存退出即可。

如果想把当前未提交的更改添加到最近的一个 commit 里，则直接执行 `git commit -a --amend` 即可。

如果要删除最近 commit 里提交的一些内容则可能会稍显麻烦一些，需要先用 `git reset HEAD^` 来撤销最近的一次 commit，
然后再用 `git checkout file` 来进行操作。

## 修改多个 commits

在开发的过程中，创建 commit 可能会比较随意，等到实际提交代码时，为了能有一个清晰的 git 提交历史，
我们可能需要重新编辑这些 commits，以使得每个 commit 都是有意义的。为了实现这个目的，我们需要使用到 git rebase。

进行 rebase 之前需要知道要进行 rebase 的 commits 的 list， 这个 list 是一个半开区间 (commit-before-you-want-to-change, HEAD],
然后通过下面的命令进行 rebase：

```shell
git rebase -i commit-before-you-want-to-change
```

修改每个 commit 前的命令即可实现对应的操作，常用的命令有：

- reword: 修改当前 commit 的 message
- squash: 把当前 commit 合并到前一个 commit，包括 commit message
- fixup:  类似 squash，但会丢弃当前 commit 的 message
- edit:   修改当前 commit

在进行 rebase 时比较麻烦的一点是获取要修改的最后一个 commit 的 hash 值。在多人协作的项目里，我们每次要进行 rebase 的 commit 应该都是由自己提交的，
基于这个假设，可以通过脚本获取最后一个不是当前作者的 commit 作为 git rebase 的参数，对应的 shell 脚本代码如下：

```shell
username="`git config user.name`"

firstOtherCommitIdx() {
	idx=0
	for (( i = 0; i < 100; i++ )); do
		current_user="$(git log --format="%an" -n 1 --skip $i)"
		if [[ $current_user != $username ]]; then
			idx=$i
			break
		fi
	done
	echo $idx
}

function main() {
	local idx="$(firstOtherCommitIdx)"
	if [[ $idx == 0 ]]; then
		echo "There is no commit for user: $username"
		exit 0
	fi
	local other_commit="$(git log --format="%H" -n 1 --skip $idx)"
	git rebase -i $other_commit
}

main $*
```
