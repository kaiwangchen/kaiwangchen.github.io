---
layout: post
title:  "Vagrant workflow"
author: kc
tags:
- vagrant
---

一个完整的项目产品，除了应用代码之外，还有很多构成部分，称之为项目环境。不论是对于刚参与的新手，还是需要在多个项目之间频繁切换的老人，或者负责线上维护的 PE 而言，项目环境由于其长期被忽视，造成了不少麻烦。于是，有了众多的标准化尝试，却常常由于推广生硬而自成障碍。换个角度看，标准化规定了要统一用什么，却不太注意怎么用，也不太注意怎么跟踪变化。有一批 DevOps 先驱者，做了很多努力，无私地贡献给大家，我有幸能作一些介绍：

0. [Vagrant workflow][vagrant-workflow] (本文幻灯片)
1. [Vagrant – 实验环境总管][vagrant-devcloud]
2. [Vagant 初印象][vagrant-putty]
3. [Vagrantfile - 从单机到集群][vagrant-vagrantfile]
4. [Vagrant 数据状态浅析][vagrant-state]
5. [Vagrant 镜像制作与共享][vagrant-box-and-repo]

好吧，花了N个周末，还是无法形成完整系列，仍差最后一步，即国内基础设施云的整合。不过针对 AWS 已经有官方插件支持。话说实验环境和生产环境还是有些不同的，比如要求快速分配释放云主机和秒级计费粒度，可能还需要关机只计存储费用，虽然快速开机和计费粒度也是[自动扩容](http://aws.amazon.com/cn/autoscaling/)的基础，但感觉只有[青云](https://www.qingcloud.com/)和根正苗红（社区关系密切）的 [UnitedStack](https://www.ustack.com/) 做的比较好。有空再做适配吧。目前只能压榨工作机了。

[vagrant-workflow]: {{ site.url }}/presentations/vagrant-workflow.pptx
[vagrant-devcloud]: {{ site.url }}/2014/06/22/vagrant-devcloud.html
[vagrant-putty]: {{ site.url }}/2014/06/29/vagrant-putty.html
[vagrant-vagrantfile]: {{ site.url }}/2014/06/29/vagrant-vagrantfile.html
[vagrant-state]: {{ site.url }}/2014/06/29/vagrant-state.html
[vagrant-box-and-repo]: {{ site.url }}/2014/07/14/vagrant-box-and-repo.html
