---
title: "基于 Docker 搭建 Jenkins Pipeline 测试环境"
date: 2017-03-12 01:29:06
tags: 
- Jenkins
- CICD
---

最近在做 CD 相关的一些工作，会用到 Jenkins Pipeline，为了方便测试，利用 Docker 搭建了一个本地的 Jenkins 服务。

<!--more-->

<!-- toc -->

## 基于 docker-compose 建 Jenkins container

使用 `docker-compose` 可以很方便地创建并启动 container，下面是用于创建 Jenkins container 的 `docker-compose.yml` 文件：

```yaml
services:
  jenkins:
    hostname: jenkins
    container_name: jenkins
    image: jenkinsci/blueocean:latest
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    volumes:
      - ./jenkins_home:/var/jenkins_home
      - ./entrypoint.sh:/entrypoint.sh
    ports:
      - "8080:8080"
```

其中 image 使用了预装了 `blue ocean` 插件的 [jenkinsci/blueocean](https://hub.docker.com/r/jenkinsci/blueocean/)。

通过把 `/var/jenkins_home` 映射到宿主机目录 `./jenkins_home` 来永久保存 Jenkins 的数据，当重启 Jenkins container 时，
类似创建的 Jenkins Job 之类的数据不会丢失。

默认的 Jenkins Container 每次启动时都会进行一遍初始化的操作，通过设置环境变量 `JAVA_OPTS=-Djenkins.install.runSetupWizard=false`
便可以防止这种行为。

通过端口映射 `8080:8080` 便可以直接在本地的 `8080` 端口访问到 container 内部的 Jenkins 服务。

## 让 Jenkins Job 自动加载修改后的 groovy 脚本

 Jenkins 的 Pipeline 是基于 groovy 语言来实现的，为了方便测试，需要 Jenkins Job 能从本地 groovy 文件加载配置。
 这可以通过 Jenkins 的 `load step` 来实现。
 
 创建一个 Jenkins Job `CD-Test`，在它的 Pipeline 配置项里选择 `Pipeline script`，并填入以下代码：
 
```groovy
node {
    load '../Jenkinsfile'
}
```

文件夹 `/path/to/project/jenkins_home` 应该有这样的目录结构：

```text
workspace
├── CD-Test
```

通过硬连接的方式把 `Jenkinsfile` 脚本连接到 `workspace` 目录下：

```shell
ln /path/to/project/Jenkinsfile /path/to/project/jenkins_home/Jenkinsfile
```

这样当你修改 `Jenkinsfile` 文件时，它会自动被 CD-Test 加载。

## 使用 jenkins-cli 工具快速新建 Jenkins build

通过 `jenkins-cli` 工具可以很方便地 实现创建一个 Jenkins Job 的 build、打开它最新的 build 等操作，下面是一个基于 `jenkins-cli` 的实用脚本：

```shell
#!/bin/bash
#
# Description: jenkins cli tool
# Author: Hongbo Liu
# Email: hbliu@freewheel.com
# CreatTime: 2017-03-10 17:43:58 CST

export JENKINS_URL="http://localhost:8080"
CLI_FILE="jenkins-cli.jar"
JOBS_DIR="/Users/hbliu/gitlab/CICD/salt/jenkins_home/jobs"

cd "$(dirname "$0")"

if [[ ! -f jenkins-cli.jar ]]; then
    wget "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
fi

open_job_build() {
    local job_name="$1"
    local url="$JENKINS_URL/blue/organizations/jenkins/$job_name/detail/$job_name"

    local build_id=$(cat "$JOBS_DIR/$job_name/nextBuildNumber")
    let build_id=build_id-1

    shift 1
    local OPT OPTARG OPTIND
    while getopts 'rn:' OPT; do
        case $OPT in
            n) build_id=$OPTARG ;;
            r)
                main build $job_name
                let build_id=build_id+1
                ;;
            ?) ;;
        esac
    done
    shift $(($OPTIND - 1))

    open "$url/$build_id"
}

main() {
    if [[ "$1" == "open" ]]; then
        shift 1
        open_job_build $*
    else
        java -jar $CLI_FILE $*
    fi
}

main $*
```


