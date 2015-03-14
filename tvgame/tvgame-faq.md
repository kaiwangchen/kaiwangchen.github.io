---
layout: doc
---
YunOS TV 游戏接入常见问题
=========================


阿里电视游戏接入，都涉及哪些事情？
---------------------------------

一般来说，要集成外设和支付。这是两个毫不相关的任务。外设适配起来费时费力，但不需要帐号联调，而支付集成通常卡在帐号和应用流程上，所以，建议前期重点做外设适配，同时启动支付集成相关流程。单机免费游戏当然就不用集成支付了。在此向单机免费游戏的开发者们致以最崇高的敬意！

在获得的 SDK 归档包里有 `Ali TV BOX Game Yunos SDK_va.b.c.d` 和 `Ali TV BOX Game Device SDK_vm.n.p` 两个目录，分别是支付和外设的相关内容。注意，目录名中的 a.b.c.d 和 m.n.p 都是版本号。这两个开发包的版本号之间没有什么特别关系，也没有遵循[语义版本号](http://semver.org/lang/zh-CN/)约定。

这俩开发包中都有文档、示例程序和类库。建议先看看文档的目录，抽选一部分章节，然后跑跑示例程序，同时结合文档中的函数说明，理解一下示例代码。这么说吧，文档和代码不应该这么组织的，但是现状就是这样，先凑合凑合吧。

只有在接入支付时才需要注册开发者（身份证明和企业支付宝），创建应用获得 `App Key`, `App Secret` 和 `Baodian Secret` 。 `App Key` 和 `App Secret` 可从[淘宝开放平台](http://open.taobao.com)上创建应用获得，但 `Baodian Secret` 目前（ 2015 年 3 月）还没有外部可获得通道，需要将`开发者帐号`、`应用名` 和 `App Key` 发给相关人员操作生成。估计一两个月后可能有点改观吧。

支付开发包中主要有支付和运营两类功能。要集成哪些运营功能，还请与相关人员沟通。


YunOS 和安卓有什么关系？
------------------------

YunOS 和安卓都是运行于 Linux 核心上的应用框架。二者采用不同的虚拟机实现，但遵守同一套字节码标准；虽有各自特色的系统服务，但通用服务兼容。所以对于应用开发人员而言，是几乎没有区别的。请自行参考 [YunOS 官网](http://www.yunos.com)和[安卓官网](https://www.android.com)。


天猫魔盒与 YunOS 是什么关系？
-----------------------------

国内市面上大多数 OTT 盒子都是采用 YunOS 系统，天猫魔盒是 OTT 盒子里销量比较大的一个品牌。


OTT 盒子是什么东西？
--------------------

OTT 是英文 Over The Top 的缩写。埃森哲在《[中国OTT-TV的前景：未来的电视](http://www.accenture.com/SiteCollectionDocuments/Local_China/PDF/Accenture-Insight-Outlook-Ott-Tv-China-Future-Tv.pdf)》报告中解释说：“在广播电视和内容发送领域， OTT意味着通过宽带发送视频和音频内容，但网络服务供应商不参与内容的控制或分发。”

OTT 盒子就是用互联网来传输数据的机顶盒，其传输线路和有线电视机顶盒的线路不一样的。有些电视机直接就支持互联网传输，称为 OTT TV ，有些电视机虽然不直接支持互联网传输，但是可以用 HDMI 线缆和 OTT 设备连接，并将信号源切换为 OTT 设备，充当 OTT 设备的大屏幕。


如何识别 YunOS 环境？
---------------------

千万不要基于 android.os.Build.MODEL 检测系统是否为 YunOS 。正确的方法是调用 com.yunos.mc.utils.McUtil 的函数：

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

终端用户可以在“应用中心”里搜索 VIP ，安装 `YunOS VIP` 应用程序，启动它就可以看到 32 个字符的完整设备编号（短横线用于视觉分组，不是设备编号的组成字符）。注意，在“系统设置”/“通用设置”/“系统信息”/“设备号”中显示的是 16 个字符的设备号，是不完整的。

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

终端用户在 YunOS TV 上完成支付需要先用淘宝帐号授权登陆，然后用支付宝帐号授权支付。有两种方式可以发起授权，一种是支付时发现没有授权，按提示切换到相应授权界面；另一种是在“系统设置”/“帐号与支付”中进行设定，先登陆淘宝帐号，然后在“支付管理”中授权支付宝在该设备上付款。登陆授权和支付授权可以分别用“手机淘宝”和“支付宝钱包”两个手机 App 来扫二维码完成，或者按提示手工完成授权流程。

登陆授权和支付授权完成后，选择商品再确认支付就行了。成功支付的订单可以在“支付宝钱包”手机 App 的账单中查到。

支付授权后，该设备将遵循支付宝移动快捷支付或短信支付业务规则，在一定额度内无需再次输入支付密码。在 YunOS 设备的“系统设置”/“帐号与支付”/“支付管理”或者“支付宝钱包”手机 App 的“财富”/“更多”/“账户与安全”/“账户授权管理”中都可以解除支付授权。


那个“宝点”是什么东西？
------------------------

“宝点”是阿里游戏的虚拟货币系统，宝点余额与淘宝帐号关联。 YunOS TV 上的游戏商品标价通常以宝点为基本单位，1 宝点和人民币的 1 分是等值的。如果商品用宝点定价，那么可以先贷宝点进行支付，然后在规定期限内偿还，不过由于是信用支付，终端用户的可贷额度是会有差异的。

在天猫上的宝点旗舰店和支付宝钱包里的阿里游戏服务窗都可以用人民币直充宝点余额。在游戏中也可以便捷地用人民币直接支付宝点定价的商品。

YunOS TV 上也有直接采用人民币定价的商品，这时就没有集成宝点，而是直接将商家系统和 YunOS TV 支付系统对接，采用支付宝授权支付。


怎么有 YunOS TV 和宝点这两套支付系统，这是什么玩法？
----------------------------------------------------

从产品功能上看，YunOS TV 支付系统是“经典款”，而宝点支付系统则是持续优化的“时尚款”，需要特定系统服务支持。使用宝点支付的应用，务必在启动时调用 `MagicCenter.isSupportAuthorize(context)` 判断环境。

从应用集成上看，宝点支付系统主要面向游戏类应用，而 YunOS TV 支付系统则面向其他所有应用。

从技术方面看， YunOS TV 支付系统负责人民币到商品的兑换，而宝点支付系统封装了 YunOS TV 支付，既支持人民币到商品的兑换，也支持宝点币到商品的兑换。如果你集成的是 YunOS TV 支付系统，那就需要按《YunOS TV 第三方支付集成指南》集成并实现回调接口；如果集成的是宝点支付系统，那需要按 9 号文档《Ali TV Box Game SDK 集成文档》第 4.5 节“宝点支付(McBaodianPay.java)”的说明集成并实现回调接口。

也就是说，YunOS TV 支付系统是 YunOS TV 上用人民币兑换任何东西的唯一渠道，但想要玩更多花样，你可以直接用宝点，也可以建立一个宝点类似的系统。


已经支付扣款，但是商品没到货，怎么破？
--------------------------------------

解决问题的关键是要判断是哪个环节出了错。

网购流程，不管是商品是实物还是虚拟物品，都可以简单理解为：顾客选择商品下单，顾客支付订单，支付系统扣款，支付系统通知商家发货，商家发货，顾客确认收货。

问题通常出现在发货通知环节。这时在顾客的“支付宝钱包” App 中账单状态时支付宝已经完成扣款。对于 YunOS TV 支付系统而言， 支付宝通知 YunOS TV 支付系统，YunOS TV 支付系统通知商家系统发货；对于宝点支付系统而言，支付宝通知宝点支付系统，而宝点支付系统通知商家系统发货。支付宝账单中的“商户订单号”和“交易号”是在下游系统中对账的线索。对账清晰后决定重新发货还是协商补偿。

支付通知处理出错的原因大抵有这几种：填错了接收通知的 URL ，通知格式有误（要特别注意区分两个支付系统的通知格式），签名或者解密算法及密钥有误，接收端程序内部错误。


晕，支付宝、YunOS TV 和宝点，到底用什么密钥呢？
-----------------------------------------------

首先要明白支付回调通知，其次要明白各种封装关系。通知时采用的密钥对是由发起回调通知的系统决定的。

如果是集成 YunOS TV 支付系统： YunOS TV 封装支付宝，所以，支付宝回调通知 YunOS TV ，YunOS TV 回调通知应用服务端。

如果是集成宝点支付系统：宝点封装 YunOS TV ，所以，支付宝回调通知 YunOS TV ，YunOS TV 回调通知宝点，宝点回调通知应用服务端。不过，系统做了内部优化，前两步通知是合并为支付宝回调通知宝点。但从逻辑层次上看，分开理解更清晰。


集成 YunOS TV 支付系统，支付时发生“非法渠道”，怎么破？
--------------------------------------------------------

类似地要首先明白支付调用，其次要明白各种封装关系。支付系统在收到应用程序的支付请求时，会判断其是否为一个合法的支付请求，从而拒绝或者扣款。

回顾一下网购简明流程：顾客选择商品下单，顾客支付订单，支付系统扣款，支付系统通知商家发货，商家发货，顾客确认收货。

再回忆一下报错的操作过程，就会发现“非法渠道”是在顾客支付订单时发生的，顾客的支付宝账单并未支付。

对于 YunOS TV 支付系统： 应用客户端封装 YunOS TV 支付 SDK ， YunOS TV SDK 封装支付宝。“非法渠道”是指 YunOS TV 支付系统不认识应用客户端，需要找阿里运营人员录入应用客户端的应用名称和包名（即 AnroidManifest.xml 中 package="..." 处定义）。


回调通知要服务端哇，单机应用上内购，怎么搞？
--------------------------------------------

准确的说法是，单机应用是收不到回调通知的。因为单机游戏一般在局域网内，从互联网向局域网回调一般是不通的。而且私钥放在客户端，从安全角度看也是不提倡的。

我们开发了内购商店系统，来支持单机应用。商品定义在内购服务后台，客户端就主动查询下单，然后通过宝点支付系统或 YunOS TV 支付系统支付，回调到内购商店服务端，供客户端查询交易结果。

内购商店支持两种商品类型，消耗品和非消耗品。消耗品购买多次，而非消耗品只能购买一次，如果你熟悉 Apple AppStore 内购系统，那可能已经猜到消耗品对应 Consumable 类型，非消耗品对应 Non-Consumable 类型。

内购商店目前支持分时段定价和礼包等功能，后面会支持兑换码和更多运营接口。


我的系统到底是哪个版本呢？
--------------------------

终端用户可以在“系统设置”/“通用设置”/“系统信息”/“固件版本”中看到具体的版本号，如 2.2.0-RS-20141101.0634 和 2.3.0-RS-20150124.1658 等。

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

这因设备而异。系统在演变过程中，要经历内测、灰度发布和正式发布几个阶段。所有终端设备都可以升级为最新的正式版，但是在灰度发布期，只有在 YunOS VIP 应用中加入“云 OS VIP 会员”的终端设备才有可以升级为灰度发布系统。内测版只有与阿里合作的开发者才可以升级获取，请先和阿里的运营人员沟通，并提交设备编号，由相关人员操作录入才能启动升级。由于设备编号较长，人工抄录容易出错，建议拍照发图。

虽然不同设备看到的最新系统是不同的，但系统升级是自愿的，都需要在“系统设置”/“通用设置”/“系统升级”中启动升级。


版本记录
--------

- v20150313a 修正宝点支付的环境探测方法
- v20150310a 公开版本
- v20150304b 修订内购商店的说明
- v20150304a 增加《YunOS TV 第三方支付集成指南》参考
- v20150302a 第三方判断 YunOS 盒子时，用 Sytem.getProperty 得不到 android 的属性值
- v20150226a 修订 YunOS 环境探测
- v20150225a 初始版本
