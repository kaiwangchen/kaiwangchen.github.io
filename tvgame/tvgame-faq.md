---
layout: doc
---
YunOS TV 游戏接入常见问题
=========================


阿里电视游戏接入，都涉及哪些事情？
---------------------------------

一般来说，要集成外设和支付。这是两个毫不相关的任务。外设适配起来费时费力，但不需要
帐号联调，而支付集成通常卡在帐号和应用流程上，所以，建议前期重点做外设适配，同时
启动支付集成相关流程。单机免费游戏当然就不用集成支付了。在此向单机免费游戏的开发者们
致以最崇高的敬意！

开发者将获得 `Ali TV BOX Game Yunos SDK_va.b.c.d` 和 `Ali TV BOX Game Device SDK_vm.n.p` 
两个 SDK ，分别是支付和外设的相关内容。注意，其中的 a.b.c.d 和 m.n.p 都是版本号。
这两个开发包的版本号之间也没有什么特别关系。

这俩开发包中都有文档、示例程序和类库。建议先看看文档的目录，抽选一部分章节，然后
跑跑示例程序，同时结合文档中的函数说明，理解一下示例代码。重点参考 SDKTestActivity 
的 onCreate 方法、 ImageOnClickListener 内部类和 Handler 匿名类。按说文档和代码不应该
这么组织的，但是现状就是这样，先凑合凑合吧。有问题请到讨论群组里咨询。

支付开发包中主要有支付和运营两类功能。要集成哪些运营功能，还请与相关人员沟通。
支付集成时需要 `App Key`, `App Secret` 和 `Baodian Secret` 。其中 `Baodian Secret` 
只有服务端才用，单机游戏不会用到。在[阿里 TV 游戏开放平台](http://open.aliplay.com)
注册开发者并创建应用即可获得这些信息。`App Key` 和 `App Secret` 对应（单机）演示程序中 
EnvConfigConstants.java 中的 APPKEY 和 APP_SECRET 。

在创建开发者时需要实名认证的淘宝帐号（身份）和支付宝账号（记账）。由于账号认证可能
牵涉到贵司内部审批流程，一般是比较麻烦的，还请提前准备。


你们的后台好多，它们之间有什么关系？
------------------------------------

感谢你们，见证了阿里 TV 游戏发展早期阶段，和我们在开发者服务上的努力。

[TV 游戏开放平台](http://open.aliplay.com) 是阿里面向 TV 游戏开发者的唯一官方平台。

[YunOS TV 开发者](http://tvdev.yunos.com) 将不再受理游戏类应用，在其上注册的游戏会
迁移到 TV 游戏开放平台中，用淘宝帐号登陆 TV 游戏开放平台后就会看到它们。如果没有，
那就在讨论群组里进行反馈，协助我们进行数据订正。

[淘宝开放平台](http://open.taobao.com) 是 TV 游戏开放平台的基础平台，但是没有提供
完整的游戏管理流程。使用过淘宝开放平台的开发者们，请移步到 TV 游戏开放平台。若在
淘宝开放平台创建过游戏，但是在 TV 游戏开放平台中没有看到该游戏，也请和我们联系订正。

淘宝帐号在三个平台上都可以登陆，是跨平台信息同步的唯一凭据。


YunOS 和安卓有什么关系？
------------------------

YunOS 和安卓都是运行于 Linux 核心上的应用框架。二者采用不同的虚拟机实现，但遵守
同一套字节码标准；虽有各自特色的系统服务，但通用服务兼容。所以对于应用开发人员而言，
是几乎没有区别的。请自行参考 [YunOS 官网](http://www.yunos.com)和[安卓官网](https://www.android.com)。


天猫魔盒与 YunOS 是什么关系？
-----------------------------

国内市面上大多数 OTT 盒子都是采用 YunOS 系统，天猫魔盒是 OTT 盒子里销量比较大的
一个品牌。


OTT 盒子是什么东西？
--------------------

OTT 是英文 Over The Top 的缩写。埃森哲在《[中国OTT-TV的前景：未来的电视](http://www.accenture.com/SiteCollectionDocuments/Local_China/PDF/Accenture-Insight-Outlook-Ott-Tv-China-Future-Tv.pdf)》
报告中解释说：“在广播电视和内容发送领域， OTT意味着通过宽带发送视频和音频内容，
但网络服务供应商不参与内容的控制或分发。”

OTT 盒子就是用互联网来传输数据的机顶盒，其传输线路和有线电视机顶盒的线路不一样的。
有些电视机直接就支持互联网传输，称为 OTT TV ，有些电视机虽然不直接支持互联网传输，
但是可以用 HDMI 线缆和 OTT 设备连接，并将信号源切换为 OTT 设备，充当 OTT 设备的大屏幕。


如何在天猫魔盒和 YunOS OTT 盒子上安装/卸载游戏并查看日志？
---------------------------------------------------------

YunOS TV系统是安卓兼容的，用 adb connect 就可以连上设备，在“系统设置”/“网络设置”
里可以查到设备 IP ，在“系统设置”/“通用设置”里可以开启远程调试模式，剩下的你们都懂的。

adb 和 Eclipse 都可以安装 apk 。但如果 apk 太大的话，建议将开发机和设备都接入有线网络，
或者拿 U 盘拷过去装（在桌面的多媒体菜单进去可以找到 U 盘）。

如何识别 YunOS 环境？
---------------------

千万不要基于 android.os.Build.MODEL 检测系统是否为 YunOS 。正确的方法是调用 com.yunos.mc.utils.McUtil 
的函数：

    static boolean isBoxYunosSystem() {
        try {
    	    Class<?> sp = Class.forName("android.os.SystemProperties");
    	    Method m = sp.getDeclaredMethod("get", String.class);
    	    if (m.invoke(sp, "ro.yunos.product.chip") != null || m. invoke(sp, "ro.yunos.hardware") != null)
    	        return true;
    	} catch (Exception e) { }
    	
        return false;
    }
    
    static boolean isMobileYunosSystem() {
        if ((System.getProperty("java.vm.name") != null && 
             System.getProperty("java.vm.name").toLowerCase().contains("lemur"))
            || (null != System.getProperty("ro.yunos.version"))) {
            return true;
        } else {
            return false;
        }
    }
    
    public static boolean isYunosSystem() {
        return isBoxYunosSystem() || isMobileYunosSystem();
    }


如何在运行时唯一识别 YunOS 设备？
---------------------------------

终端用户可以在“应用中心”里搜索 VIP ，安装 `YunOS VIP` 应用程序，启动它就可以看到
32 个字符的完整设备编号（短横线用于视觉分组，不是设备编号的组成字符）。注意，
在“系统设置”/“通用设置”/“系统信息”/“设备号”中显示的是 16 个字符的设备号，是不完整的。

开发人员也可以用这个函数来获取设备编号：

    public static String getUuid(){
        try {
             Class<?> cloudUuid = Class.forName("com.yunos.baseservice.clouduuid.CloudUUID");
             Method m = cloudUuid.getMethod("getCloudUUID");
             String result = (String)m.invoke(null);
             return result;
         }catch (Exception e) {
            return "false";
         }
     }


在 YunOS TV 设备上如何支付？
----------------------------

终端用户在 YunOS TV 上完成支付需要先用淘宝帐号授权登陆，然后用支付宝帐号授权支付。
有两种方式可以发起授权，一种是支付时发现没有授权，按提示切换到相应授权界面；
另一种是在“系统设置”/“帐号与支付”中进行设定，先登陆淘宝帐号，然后在“支付管理”中
授权支付宝在该设备上付款。登陆授权和支付授权可以分别用“手机淘宝”和“支付宝钱包”
两个手机 App 来扫二维码完成，或者按提示手工完成授权流程。

登陆授权和支付授权完成后，选择商品再确认支付就行了。成功支付的订单可以在“支付宝钱包”
手机 App 的账单中查到。

支付授权后，该设备将遵循支付宝移动快捷支付或短信支付业务规则，在一定额度内无需
再次输入支付密码。在 YunOS 设备的“系统设置”/“帐号与支付”/“支付管理”或者
“支付宝钱包”手机 App 的“财富”/“更多”/“账户与安全”/“账户授权管理”中都可以解除支付授权。


那个“宝点”是什么东西？
------------------------

“宝点”是阿里游戏的虚拟货币系统，宝点余额与淘宝帐号关联。 YunOS TV 上的游戏商品标价
通常以宝点为基本单位，1 宝点和人民币的 1 分是等值的。如果商品用宝点定价，那么可以
先贷宝点进行支付，然后在规定期限内偿还，不过由于是信用支付，终端用户的可贷额度
是会有差异的。

在天猫上的宝点旗舰店和支付宝钱包里的阿里游戏服务窗都可以用人民币直充宝点余额。
在游戏中也可以便捷地用人民币直接支付宝点定价的商品。

YunOS TV 上也有直接采用人民币定价的商品，这时就没有集成宝点，而是直接将商家系统
和 YunOS TV 支付系统对接，采用支付宝授权支付。


怎么有 YunOS TV 和宝点这两套支付系统，这是什么玩法？
----------------------------------------------------

从应用集成上看，宝点支付系统主要面向游戏类应用，而 YunOS TV 支付系统则面向其他所有应用。

从技术方面看， YunOS TV 支付系统负责人民币到商品的兑换，而宝点支付系统封装了
YunOS TV 支付，既支持人民币到商品的兑换，也支持宝点币到商品的兑换。如果你集成的是
YunOS TV 支付系统，那就需要按《YunOS TV 第三方支付集成指南》集成并实现回调接口；
如果集成的是宝点支付系统，那需要按《Ali TV Box Game SDK 集成文档》
第 4.5 节“宝点支付(McBaodianPay.java)”的说明集成并实现回调接口。

也就是说，YunOS TV 支付系统是 YunOS TV 上用人民币兑换任何东西的唯一渠道，但想要
玩更多花样，你可以直接用宝点，也可以建立一个宝点类似的系统。


已经支付扣款，但是商品没到货，怎么破？
--------------------------------------

解决问题的关键是要判断是哪个环节出了错。

网购流程，不管是商品是实物还是虚拟物品，都可以简单理解为：顾客选择商品下单，
顾客支付订单，支付系统扣款，支付系统通知商家发货，商家发货，顾客确认收货。

问题通常出现在发货通知环节。这时在顾客的“支付宝钱包” App 中账单状态时支付宝
已经完成扣款。对于 YunOS TV 支付系统而言， 支付宝通知 YunOS TV 支付系统，
YunOS TV 支付系统通知商家系统发货；对于宝点支付系统而言，支付宝通知宝点支付系统，
而宝点支付系统通知商家系统发货。支付宝账单中的“商户订单号”和“交易号”是在下游系统中对账
的线索。对账清晰后决定重新发货还是协商补偿。

支付通知处理出错的原因大抵有这几种：填错了接收通知的 URL ，通知格式有误（要特别注意
区分两个支付系统的通知格式），签名或者解密算法及密钥有误，接收端程序内部错误。


我该用哪个密钥？
----------------

电视游戏接入时，客户端会用到应用密钥，服务端向宝点系统下单会用到宝点密钥。

如果以前集成过 YunOS TV 支付系统，那应该记得下单用的是 YunOS TV 应用的 RSA 密钥。
如果以前集成过支付宝支付系统，那应该还记得下单用的是支付宝密钥。

简单地说，上面提到的四个密钥互不通用。

具体一点就是，这涉及分布式系统主调与回调。主调方可能同步获得返回结果，也可能触发回调，
异步返回结果。若主调了一个系统的接口，该系统又依赖于其它系统来完成功能，称该系统封装了其依赖的系统。

主调哪个系统的 SDK ，就得使用该系统约定的密钥（如电视游戏接入的应用密钥），
或加入其访问控制列表（如 YunOS TV 包名注册）；哪个服务系统发起 HTTP 回调通知，
它就使用自己约定的密钥对。

如果是集成 YunOS TV 支付系统： YunOS TV 封装支付宝，所以，支付宝回调通知 YunOS TV ，
YunOS TV 回调通知应用服务端。这时使用的是 YunOS TV 的 RSA 密钥对。

如果是集成宝点支付系统：宝点封装 YunOS TV ，所以，支付宝回调通知 YunOS TV ，
YunOS TV 回调通知宝点，宝点回调通知应用服务端。这是使用的是宝点的请求签名共享密钥。


怎么组合都是签名失败 ILLEGAL_SIGNATURE ，这个签名到底怎么算的！
--------------------------------------------------------------

这里只讨论宝点 1.0.3.3 及更高版本的支付 SDK 。

首先要确保 AppKey 和 AppSecret / Baodian Secret 无误，一个字都不能抄错哦。

有两个地方会涉及签名，客户端发起调用时，这时用的是 `AppKey` 和 `AppSecret` ；服务端
和宝点服务器之间用的是 `AppKey` 和 `Baodian Secret` 。

在服务端和宝点服务器之间的请求签名算法是，将各参数按 **字典序** 串起来，再追加 
`Baodian Secret`，得到形如 `key1value1key2value2...BaodianSecret` 的字符串，然后
计算该字符串的 md5 值。

但注意 (1) key 都是小写的（文档里有很多首字母大写的参数，那是习惯不严谨的文档员用
Word 写技术文档留下的痕迹）；(2) 参数值必须是 GBK 编码的，而由于 GBK 兼容 ASCII ，
纯英文怎么搞都没事。文档里称 `_input_charset` 可以声明编码为 UTF8 ，那是骗你滴，不过
`_output_charset` 倒是有效的。

举例来说，title取值“100金币”，在计算 md5 时参与计算的是 “title100金币”，更准确地说，
是 `74 69 74 6c 65 31 30 30 bd f0 b1 d2` 这 16 个字节，其中 `bd f0 b1 d2` 是“金币”的
GBK 编码的十六进制表示（一个汉字两个字节）。在 `LANG=en_US.UTF-8` 环境下，用
 `echo -n title100金币 | iconv -f utf8 -t gbk` 可以获得原始字节序列。在 HTTP 请求中，
该参数是 `title=100%BD%F0%B1%D2` ，因为还需要经过 [urlencode 编码](http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1)。


获取消费 token 时，接口返回请求签名超时 SIGNATURE_EXPIRED ，可能是什么原因导致的呢？
------------------------------------------------------------------------------------

这个响应是这样的吧：

    {"app_order_id":"...","error_code":"SIGNATURE_EXPIRED","is_success":"F","msg":"请求签名过期"}
    
注意，在 applyConsume 时，有个 ts 参数表示请求时间戳。宝点服务器会检查这个时间戳，
如果与当前时间相差太大的话（几分钟），它就会报这个错误。

出现这种问题的情况一般有两种：其一是你的服务器时间漂移了，这时要提醒运维人员保持服务器时钟同步。
其二是你可能正在手工模拟请求，这时你就得选个合适的 ts 值了，别和发出请求的时间点偏差太大。


听说有个激励系统，怎么集成呢？
------------------------------

是的，激励系统可以根据场景来发放奖品，比如说登陆送积分，也就是说在登录的场景下，
玩家可以获得类型为平台积分的奖品。平台积分可以在积分商城里购物。此外，有些场景是需要
消耗一些积分才能获得准入资格的。

集成激励接口说白了就是游戏客户端通过 `getLotteryResultWithPermission(eventKey, "", "", listener)`
到激励系统中查一下有没有可以发给当前用户的奖品，并在 listener.onResult 回调中提示用户已经获得奖品。
而激励系统自动根据奖品类型调用相应系统服务端接口，从而完成发放。

显然，只有平台登陆用户才能参与激励。

eventKey 是场景标识，需要 CP 和阿里运营协商一致，且由阿里运营在后台操作配置完成。
具体在那些点触发激励查询，也是 CP 和运营协商决定的。

如果程序需要向用户展示场景信息，可以通过 `getActivitesInfo(eventKey, listener)` 接口查询。


集成 YunOS TV 支付系统，支付时发生“非法渠道”，这是怎么回事？
------------------------------------------------------------

类似地要首先明白支付调用，其次要明白各种封装关系。支付系统在收到应用程序的支付请求时，
会判断其是否为一个合法的支付请求，从而拒绝或者扣款。

回顾一下网购简明流程：顾客选择商品下单，顾客支付订单，支付系统扣款，支付系统通知商家发货，
商家发货，顾客确认收货。

再回忆一下报错的操作过程，就会发现“非法渠道”是在顾客支付订单时发生的，顾客的支付宝账单并未支付。

对于 YunOS TV 支付系统： 应用客户端封装 YunOS TV 支付 SDK ， YunOS TV SDK 封装支付宝。
“非法渠道”是指 YunOS TV 支付系统不认识应用客户端，需要找阿里运营人员录入应用客户端的
应用名称和包名（即 AnroidManifest.xml 中 package="..." 处定义）。


回调通知要服务端哇，单机应用上内购，怎么搞？
--------------------------------------------

准确的说法是，单机应用是收不到回调通知的。因为单机游戏一般在局域网内，从互联网向局域网回调
一般是不通的。而且私钥放在客户端，从安全角度看也是不提倡的。

我们开发了内购商店系统，来支持单机应用，将于 5 月下旬发布。商品定义在内购服务后台，
客户端就主动查询下单，然后通过宝点支付系统或 YunOS TV 支付系统支付，回调到内购商店服务端，
供客户端查询交易结果。

内购商店系统将于 5 月下旬发布，在此之前，单机游戏需将 notifyUrl 设为 `http://localhost/coin/mockGateway.htm`
来生成订单，表示其无需回调。这些接口非常生硬，我们将在 5 月下旬发布的版本中改进。

内购商店支持两种商品类型，消耗品和非消耗品。消耗品购买多次，而非消耗品只能购买一次，
如果你熟悉 Apple AppStore 内购系统，那可能已经猜到消耗品对应 Consumable 类型，
非消耗品对应 Non-Consumable 类型。

内购商店目前支持分时段定价和礼包等功能，后面会支持兑换码和更多运营接口。


我的系统到底是哪个版本呢？
--------------------------

终端用户可以在“系统设置”/“通用设置”/“系统信息”/“固件版本”中看到具体的版本号，如
2.2.0-RS-20141101.0634 和 2.3.0-RS-20150124.1658 等。

开发人员可以参考以下代码：

    import android.os.Build;
    String v = Build.VERSION.RELEASE;
    
    import java.util.regex.Pattern;
    import java.util.regex.Matcher;
    public class Version {
        private static Pattern p = Pattern.compile("^(\\d+)\\.(\\d+)\\.(\\d+)-");
        public static final Version V230 = new Version(2, 3, 0);
        private int major;
        private int minor;
        private int patch;

        public static Version parse(String v) {
            Matcher m = p.matcher(v);

            if (m.find()) {
                int count = m.groupCount();
                if (count < 3)
                    throw new IllegalArgumentException(v);
                int major = Integer.parseInt(m.group(1));
                int minor = Integer.parseInt(m.group(2));
                int patch = Integer.parseInt(m.group(3));
                return new Version(major, minor, patch);
            }
            throw new IllegalArgumentException(v);
        }

        private Version(int major, int minor, int patch) {
            this.major = major;
            this.minor = minor;
            this.patch = patch;
        }

        public boolean gt(Version v) {
            return (major > v.major ||
                   (major == v.major && minor > v.minor) ||
                   (major == v.major && minor == v.minor && patch > v.patch))
                ? true : false;
        }

        public boolean eq(Version v) {
            return (major == v.major && minor == v.minor && patch == v.patch)
                ? true : false;
        }

        public boolean ge(Version v) {
            return gt(v) || eq (v);
        }


到底那个版本的系统是最新的？
----------------------------

这因设备而异。系统在演变过程中，要经历内测、灰度发布和正式发布几个阶段。所有终端设备
都可以升级为最新的正式版，但是在灰度发布期，只有在 YunOS VIP 应用中加入“云 OS VIP 会员”
的终端设备才有可以升级为灰度发布系统。内测版只有与阿里合作的开发者才可以升级获取，
请先和阿里的运营人员沟通，并提交设备编号，由相关人员操作录入才能启动升级。由于
设备编号较长，人工抄录容易出错，建议拍照发图。

虽然不同设备看到的最新系统是不同的，但系统升级是自愿的，都需要在“系统设置”/“通用设置”/“系统升级”
中启动升级。


版本记录
--------

- v20150421a 问题改为“该用哪个密钥”
- v20150420a 增加 SIGNATURE_EXPIRED 说明
- v20150417a 严肃一点
- v20150415a 增加激励系统集成说明
- v20150409b 中文编码可能导致签名失败
- v20150409a 阿里 TV 游戏开放平台是唯一官方入口
- v20150313a 修正宝点支付的环境探测方法
- v20150310a 公开版本
- v20150304b 修订内购商店的说明
- v20150304a 增加《YunOS TV 第三方支付集成指南》参考
- v20150302a 第三方判断 YunOS 盒子时，用 Sytem.getProperty 得不到 android 的属性值
- v20150226a 修订 YunOS 环境探测
- v20150225a 初始版本
