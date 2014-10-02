---
layout: post
title:  "Linux Container 和 Docker 技术基础"
author: kc
tags:
- Linux container
- docker
---

昨天下午 [Docker 中文社区][dockboard]的[第二次线下活动][dockerbj2]中，UCloud 资深工程师[邱模炯][qiumojiong]做了题为《[Container 内核原理介绍][container internals]》的技术分享，是我见过的最简洁最明白的容器技术介绍，没有之一！点上述链接即可在数分钟之内洞悉容器虚拟化的原理。

被隔离并限额的容器如何互相通信呢？可以参考 Docker 官方网络手册 [Advanced Networking][docker networking] （长文慎入），网络似乎有点卡……简单的讲就是建立虚拟链路，把链路两端扔到不同容器中，或者一端扔到容器中，另一端放在宿主机，然后在宿主机用网桥把需要连通的容器桥接起来。

**更新 2014-09-29:** InfoQ 有一个 [Docker 专栏][infoq dockers]，但最有意思的当属 《[Docker源码分析][docker code reading]》一文。

[dockboard]: https://www.dockboard.org/
[dockerbj2]: https://www.dockboard.org/docker-beijing-meetup-2-keynotes/
[qiumojiong]: https://www.dockboard.org/docker-meetup-2-speaker-qiu-mo-jiong/
[container internals]: http://docker.u.qiniudn.com/container%E5%86%85%E6%A0%B8%E5%8E%9F%E7%90%86%E6%B5%85%E8%B0%88.ppt
[docker networking]: https://docs.docker.com/articles/networking/
[infoq dockers]: http://www.infoq.com/cn/dockers/
[docker code reading]: http://www.infoq.com/cn/articles/docker-source-code-analysis-part1
