---
layout: post
title: Unite China 2014 大会归来
author: kc
tags:
- unite china
- A&#47;B Testing
- MMO
- MSO
- AVOS
- Everyplay
wordpress_id: 428
wordpress_url: http://kaiwangchen.com/blog/?p=428
date: 2014-04-15 00:26:26 +0800
---

2014/4/13-14 国家会议中心，重温开发者大会的感觉，年轻时求知的身影历历在目。时转今日，又是新的开始，两天下来，心情跌宕起伏，而收获颇丰。有些所想做的事情，已经有人做得很好了，顿感压力袭来；而看到一些人的努力，又有一种找到知音的感觉。 最吸引我的几个议题，按时间顺序分别是

1.  Splitforce CEO Zac Aghion 和 CTO David Ruiz 带来的 workshop：A/B Testing
2.  Unity Clould 深度集成的交叉推广
3.  AVOS Cloud CTO 丰俊文带来的 AVOS 游戏云介绍
4.  制作人会场里 Madfingergames 主程 Petr Benysek 带来的 Death Trigger 介绍
5.  Unity 研发总监 Erik Juhl 带来的未发布特性 UNET 介绍
6.  乐逗游戏 iDreamSky 的 Rimi Breton 带来的 Asset Optimization for mobile games <!--more-->

没错，几乎都是老外的分享，你懂的。

## Splitforce CEO Zac Aghion 和 CTO David Ruiz 带来的 workshop：A/B Testing

这是一个支持 A/B 测试的云服务，具体介绍见 [splitforce.com][1] ，简单的说就是先到 splitforce.com 上去注册 app 账号并创建实验，设置好 A 组参数和 B 组参数，以及 A/B 的划分；并将模板代码复制到三个地方，1) app 初始化时，向 splitforce server 请求一组参数，具体是哪组，由划分策略决定，2）在游戏逻辑中使用获取的参数值，3）当玩家触发逻辑时予以记录，并提交到 splitforce server 。然后，登陆 splitforce 后台，就可以看到 A 组玩家和 B 组玩家的统计对比。 后面的社区活动中， Unity 社区负责人说 David Ruiz 有点小紧张……还好吧，不过他俩中文还算不错了。简单聊了几句，得知 David 常驻北京，可以随时上门提供咨询。

## Unity Cloud 深度集成的交叉推广

赶上了半场，似乎是 Unity 集成了新收的 Everyplay ，向玩家提供后台录像及视频分享功能，也就是借视频攻略和特炫录像来扩大影响，这倒也是个办法。后台录像功能的手机系统资源消耗是 10MB 内存，每帧占 CPU 1.5ms ，每分钟 10MB ，可循环录制。看来 Unity 走的还是终端（玩家）路线。

## AVOS Cloud CTO 丰俊文带来的 AVOS 游戏云介绍

这是一个 Yahoo Games Network 类似产品，感觉其目标定位是快速开发小应用。提供 Node.js 服务端环境、数据分析服务、推送和云存储。只有存储收费 （500 万次以上），其他服务免费。幻灯片做的很专业。客户端-服务端之间基于 websocket 通信，并发支持也比较高（单机保持 100 万连接），一分钟可以推一遍所有客户端，典型的 Proactor/Reactor 模型优势。幻灯片里提到了个事件流，还没来得及打听，哥们就找不着人了……艹，闪得真快！

## 制作人会场里 Madfingergames 主程 Petr Benysek 带来的 Death Trigger 介绍

这是一款生化危机题材的 MSO ，没错，是 MSO ，全称是 Massive Single-player Online 。据介绍 Death Trigger II 全面使用云服务，当然鉴于 Single-player 本质，也就是存存档（如任务进度和 IAP ），当然还有世界广播。

## Unity 研发总监 Erik Juhl 带来的未发布特性 UNET 介绍

第一天上午在展台逛了两圈，进主会场第一个听到就是 UNET ，立马被吸引！当时就有个预感，果然验证了：

这是激动人心的特性，Unity 即将支持 MMO 后端开发。一旦发布，估计会秒杀所有后端框架。其架构应该是 game application layer + game logic + game view 经典三大件组成的 event-oriented architecture ，UNET 提供的是 authoritative server 上的 remote game view 和 remote game client 上的 remote game logic 支持，以及 remote game view 和 remote game logic 之间的封装的通信协议。client sdk 的使用风格可能和 Google Cloud Platform 的差不多，都是通过 notation 来生成代码。

目前完成了一期，即提供协议封装、client sdk、 match maker 及 replay server 服务，后续二三期会提供逻辑验证，但是尚无具体日程。所谓的 match maker 即是开房间支持，玩家向 match maker 发起连接创建房间，match maker 通过 relay server 将请求转给 game server ，game server 创建房间，随后玩家就向 relay server 发起连接准备接受游戏状态更新。这里的 replay server 有点像接入服务器 connector ，只不过国内常见架构 match maker 可能是躲在 connector 之后的，而在 UNET 的设计里，match maker 是暴露在外面的。match maker 和 relay server 都由 Unity Cloud 提供，game server 该放在哪，是二期考虑的事情。

通信协议他们基于 UDP 搞了一个，原因还是那几条：fast action 游戏可以容忍丢包，TCP 协议存在 head-of-line blocking 短板。该协议支持 QoS 和 multiplexing ，但没有使用 [QUIC][2] ，据称是场景不合。网络模型上，还是典型的 Proactor/Reactor 风格（基于 Windows IOCP 或 Linux epoll）。

## 乐逗游戏 iDreamSky 的 Rimi Breton 带来的 Asset Optimization for mobile games

主要是客户端的优化，比如因 CPU 和 GPU 之间的带宽问题需要将 Asset 打包，视情况减少骨骼数量，降低纹理质量之类的。感觉 Rimi 是个低调的大牛，于是去索要了联系方式。

## 一些小插曲

1.  UCloud 晚场爆满，白天会场的都流到这里来，还有冷餐，不爆场才怪！被挡在外面的同学，务必吸取教训，吃饭不积极，思想有问题阿。
2.  制作人场的 Sheep Happens 嘉宾是俩俄罗斯美女。

 [1]: https://splitforce.com/
 [2]: http://en.wikipedia.org/wiki/QUIC
