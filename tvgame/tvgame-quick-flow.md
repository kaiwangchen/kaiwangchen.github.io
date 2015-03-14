---
layout: doc
---
电视游戏接入简易流程
====================

版本记录
--------

- v20150314a 补充流程邮件格式
- v20150313a 在线版，澄清“无线手机游戏”标签，引入小二代号
- v20150312e 增加流程有效期和替代方案
- v20150312d 增加 tvdev 用户和企业支付宝账号的说明
- v20150312c 增加错误代码说明

简易流程
--------

本[简易流程](http://kaiwangchen.github.io/tvgame/tvgame-quick-flow.html)将在[阿里游戏开放平台](http://open.aliplay.com)提供完整自助流程时（2015年4月中旬）失效。

1. 在 open.taobao.com 注册开发者账号，并向 _小二_ 提供 **开发者账号** （即淘宝账号），安排内部流程处理。处理后才有“无线手机游戏”标签。如果之前在 open.taobao.com 注册过账号，请尝试创建应用，看有没有“无线手机游戏”标签，如果没有的话，那也请将开发者账号发给 _小二_ ，但不必重复创建账号。
2. 创建应用，必须选 **无线手机游戏** 标签（你没看错，是这个名字叫错了）。将 **公司名** 、 **游戏名** 、 **App Key** 和 **企业支付宝账号** 发给 _小二_ ，他来提供 Baodian Secret 。
3. 开发者有了 **App Key** 、 **App Secret** 和 **Baodian Secret** ，就可以在客户端接入支付了。 单机游戏开发者，请参考 9 号文档 Ali TV BOX Game Yunos SDK_v1.0.3.3 的 4.5.2.2 节。如果游戏有服务端，那还需要接入支付回调，参见 9 号文档的 4.5.2.1 （通过服务端获取 Token ，即下单）和 4.5.4 （合作商扣款通知，即扣款后回调）。
4. 开发者在 open.taobao.com 发布应用，即可去掉 API 调用限制。

注：这里 _小二_ 是一个代号，特指阿里游戏的接入支持同学，商务知道他的 email 和手机号码。每款游戏至少有一个小二在支持，但未必是同一个人。

以上流程可能需要同步两次信息给 _小二_ ，请发邮件给他。商务知道他的邮件地址。

* 步骤 1 发的邮件提供 **公司名称** 和 open.taobao.com 的 **开发者账号** 。

    邮件标题：游戏开发者账号标记申请
    邮件内容：
        开发者账号：<淘宝昵称>
        公司名称：<公司名称>

* 步骤 2 发的邮件提供 **应用名称** 、 **App Key** 和 **企业支付宝登陆账号** 和 **企业支付宝账号ID** (那串数字一般是 2088 打头的) 。

    邮件标题：游戏应用宝点密钥申请
    邮件内容：
        开发者账号：<淘宝昵称>
        公司名称：<公司名称>
        应用名称：<游戏名称>
        App Key：<在 open.taobao.com 中创建的带“无线手机游戏”标签的应用的 App Key>
        企业支付宝账号：<分账用的企业支付宝账号登录名>
        企业支付宝账号ID：<上面这个账号的 2088 打头的数字 ID >


注意事项
--------

tvdev.yunos.com 的开发者，请新注册 open.taobao.com 账号。

步骤 2 中提供给 _小二_ 的必须是企业支付宝账号，不能是个人账号。这个账号是分账用的，请先准备好。

请先运行 TV BOX Game Yunos SDK_v1.0.3.3 下的 Ali TV BOX  Game Demo SDK 演示程序，重点参考 SDKTestActivity 的 onCreate 方法、 ImageOnClickListener 内部类和 Handler 匿名类。上面流程获得的 App Key 、App Secret 和 Baodian Secret 对应 EnvConfigConstants.java 中的 APPKEY APP_SECRET 和 BAODIAN_SECRET_KEY 。

由于步骤 2 和步骤 3 之间预计需要 **一天时间** （这么慢！可这就是现状……），请务必在等待期间抓紧理解演示程序，避免耽误整体进程。

在 9 号文档的第 5 章（即附录）有错误码说明供开发者自行参考。


附：启动逻辑可参考以下伪代码
----------------------------

    if (MagicCenter.isSupportAuthorize(ctx)) {
        if (McUser.isAuth()) { // 1. 会触发网络调用，注意不要阻塞主 UI 
            // with-account mode
        } else {
            // prompt: loginAndAuth or guest mode
            if (loginAndAuth) {
                McUser.loginAuth(0); // 2. 会触发网络调用，注意不要阻塞主 UI 。
                                     // 此处先登陆后授权，放弃登陆则返回游戏，放弃授权则回调 AuthListener.onError -2205 。
            }
            else {
                // guest mode
            }
        }
        
    } else {
        // prompt: update tip or guest mode
    }
    
    if (with-account mode) {
    }
    else if (guest mode) {
    }
    else if (update tip) { 
    }
    else {
        // quit
    }
