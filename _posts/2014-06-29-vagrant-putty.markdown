---
layout: post
title: Vagrant 初印象
author: kc
tags:
- vagrant
- putty
- windows
wordpress_id: 495
wordpress_url: http://kaiwangchen.com/blog/?p=495
date: 2014-06-29 17:34:26 +0800
---

那么，开始 Vagrant 之旅吧！请先到[这里][1]下载安装文件。本篇主要讨论 Windows 下使用 Vagrant 管理 Linux 环境的一些问题。 Unix 类系统的用户很幸福，这里的多数问题可能都不会遇到，因为 [OpenSSH][2] 客户端和大 /home 分区几乎是标配。如果需要管理的是 Windows 环境，那也是没有问题的，因为自 Vagrant 1.6 版本起，已经开始支持[管理 Windows 虚拟机][3]。

## Vagrant 过程浅析

在命令提示符下执行

    vagrant init hashicorp/precise32
    vagrant up
    vagrant ssh     # 或者是 putty ，见下文 vagrant-multi-putty 介绍
    vagrant halt    # 关闭虚拟机
    vagrant destroy # 销毁虚拟机
    

第一步在当前目录生成一个 [Vagrantfile][4] 文件，指定使用 [hashicorp/precise32 镜像][5]。Vagrantfile 是项目的开发环境定义文件，需加入到代码仓库中，其他人就可以检出项目后 `vagrant up` 获得相同的实验环境。由于本机暂无该镜像文件，第二步先自动下载大小为 282MB 的 [HashiCorp 官方 Ubuntu 12.04 LTS 32-bit 镜像][6]，导入到 `VAGRANT_HOME/boxes/hashcorp-VAGRANTSLASH-precise32/1.0.0/virtualbox` 目录中（注意 1.0.0 是镜像版本，这是个好习惯），从该镜像创建虚拟机，修改虚拟机的物理属性（如内存、CPU 和 MAC），设置端口转发和共享目录，启动虚拟机，然后登入虚拟机做一些配置<!--more-->。由于暂未定义 provision ，所以没有触发安装各种软件。

在第二步后打开 Windows 任务管理器，就会发现多了一个 `VBoxHeadless.exe` 进程，而打开 VirtualBox 虚拟机管理器，也可以看到虚拟机列表里多了一个运行中虚拟机实例。这就是 vagrant 启动的虚拟机，但和 VirtualBox 虚拟机管理器上普通方式（`--mode gui`）启动的实例不一样，这个实例没有虚拟屏幕界面。实际上，这个过程对应的主要 [VBoxManage][7] 命令是

    VBoxManage import VAGRANT_HOME/.../vbox.ovf
    VBoxManage startvm <uuid> --mode headless
    

笔记本用户还可能会遇到因 “VT-x/AMD-v 硬件加速”虚拟机无法启动的警告。这跟 Vagrant 没关系，而是因为 VirtualBox 虚拟化希望利用 [CPU 的硬件特性][8]，重启物理机进入 BIOS 找到 Virtualization 配置，启用即可。

即便如此，这个典型过程在 Windows 上还是会不太顺畅的，因为 Windows 系统默认不带 ssh.exe 客户端，上面第三步无法直接登录到虚拟机中，而是给出登录信息让大家用自己熟悉的 ssh 客户端。

## 艹，系统盘又快满了

作为一个被采用双盘 Windows 7 操作系统，不得不时刻关注系统盘剩余空间的屌丝用户，会马上意识到 VirtualBox 虚拟机磁盘和 Vagrant 镜像都是吃硬盘空间的大户，故有必要采取一些措施：

1.  打开 Oracle VM VirtualBox 管理器，选“管理 > 全局设定”菜单，注意到“常规 > 默认虚拟电脑位置”是 C:/Users/kc/VirtualBox VMs ，将这个目录改到 D: 盘下。
2.  Vagrant 镜像，即所谓的 [box 文件][9]，是放在 VAGRANT_HOME/box 中的，而 VAGRANT_HOME 默认是 USERPROFILE/.vagrant.d ，在 Windows 7 上 [USERPROFILE][10] 是指 C:/Users/<用户名>/ ，故需在 “计算机右键菜单 > 属性 > 高级系统设置 > 环境变量 > 系统变量”，添加用户环境变量 VAGRANT_HOME 指向 D: 盘中的目录。注意这里是[用户环境变量][11]，而不是系统环境变量，因为 [vagrant 的全局状态][12]在设计上区分用户的。

其实最好是可以将用户数据目录都迁移出系统盘，但似乎 Windows 对此[没有很好的支持][13]。

## Windows 宿主机上如何便捷登入虚拟机

话说 Windows 依然是[最流行的][14]桌面操作系统，办公休闲娱乐都很方便，但个人感觉对程序员还是很不友好，很多开发工具缺失或者安装过程麻烦。ssh 客户端就是一例， [SecureCRT][15] 虽然好用但价格昂贵，满天飞的盗版显然是不合法的， [XShell][16] 在非教育或私用场合下也有不菲的许可证费用，cygwin 或者 GIT 带的那个 ssh.exe 虽然免费但要多傻有多傻。感谢 [Simon Tatham][17] 贡献了经典而且免费的 [PuTTY][18] ，才让这屌丝的日子有了一些慰藉。然而屌丝的人生总是不会太顺畅的，PuTTY 不在 Vagrant 官方支持范围内，虽然有个第三方插件 [vagrant-multi-putty][19] ，但没有随 Vagrant 的升级而更新，不能兼容 vagrant 1.5 及往后版本。值得庆幸的是，万能的开源社区总是能够给出靠谱的解决方法，可惜插件作者似乎蒸发了，所以这个 [patch][20] 还没能合并到代码仓库，目前还只能手工修改生效。

顺便说一句，Simon Tatham 还写过一篇媲美 [Eric Steven Raymond][21] 《[提问的智慧][22]》的经典文章 [How to Report Bugs Effectively][23] ，已翻译成包括[中文][24]在内的多种语言，是计算机从业人员的必读材料。

下面我们来看看整个过程：

先下载 PUTTY.EXE 并将其目录追加到 Windows 环境变量 [PATH][25] 中。建议下载整个 [PuTTY 工具包][26]，以便不时之需。顺便说一句，鉴于 Windows 的软件包普遍缺乏数字签名或者不便校验出处，千万千万不要百度下载所谓的汉化版，小心被植入木马病毒哦！看一看前年的这篇报道《[中文版putty后门事件分析][27]》。

然后安装插件

    $ vagrant plugin install vagrant-multi-putty
    

打开 `VAGRANT_HOME/.vagrant.d/gems/gems/vagrant-multi-putty-1.4.3/lib/vagrant-multi-putty/command.rb` ，其中 VAGRANT_HOME 是指 vagrant 的全局状态目录，这个全局是按用户的，即设计上每个用户都应该有他自己的 VAGRANT_HOME 。

原第 8 ~ 9 行

      options = {:modal => @env.config_global.putty.modal,
           :plain_auth => false }
    

改成

      # config_global is deprecated from v1.5
      if Gem::Version.new(::Vagrant::VERSION) >= Gem::Version.new('1.5')
        @config = @env.vagrantfile.config
      else
        @config = @env.config_global
      end
    
      options = {:modal => @config.putty.modal,
                 :plain_auth => false }
    

原第 46 行

    @env.config_global.putty.after_modal_hook.call
    

改成

    @config.putty.after_modal_hook.call
    

兼容性问题就解决了。

但 PuTTY 和 OpenSSH 的密钥格式是不同的，所以还需要用 Putty Key Generator 将官方镜像的私钥 insecure_private_key 转换为 PuTTY 密钥格式。打开 PUTTYGEN.EXE ，选 “Conversions > Import key” ，找到 `VAGRANT_HOME/insecure_private_key` ，点 OK 然后 Save private key 到 `VAGRANT_HOME/insecure_private_key.ppk` 即可。

至此，就可以用 PuTTY 登陆虚拟机了：

    $ vagrant putty
    

当然，这么简单的场景体现不了 vagrant-multi-putty 的优越性。如果实验环境有多个虚拟机的，甚至，有多套实验环境呢？在每一个实验环境下，用统一的命令

    $ vagrant putty <vm>
    

显然比在 PuTTY 里每个虚拟机连接参数都配一遍要清爽得多。

什么！你的开发环境不能自由访问互联网？！好吧， vagrant, putty, puttygen , vagrant-multi-putty 和 hashicorp/precise32 镜像都可以预先下载，然后离线使用。vagrant-multi-putty 安装命令行中不使用插件名，而是用下载的 gem 安装包路径即可。镜像则需要预先加入 Vagrant：

    $ vagrant add hashicorp/precise32 USERPOFILE/Downloads/precise32.box
    $ vagrant init hashicorp/precise
    $ vagrant up
    

当然也可以自己搭建一个镜像服务器，然后用 `VAGRANT_SERVER_URL` 环境变量指向它。所谓上有政策下有对策。但换个角度看看，你为什么要在这充斥着障碍的环境中让宝贵的时间无谓地消耗呢，考虑换个地方吧！只有自由开放的土壤才能滋养创新的灵魂。

 [1]: http://www.vagrantup.com/downloads
 [2]: http://www.bsdcan.org/2012/schedule/attachments/193_SSH%20Mastery%20BSDCan%202012-public.pdf
 [3]: http://www.vagrantup.com/blog/feature-preview-vagrant-1-6-windows.html
 [4]: http://docs.vagrantup.com/v2/vagrantfile/index.html
 [5]: https://vagrantcloud.com/hashicorp/precise32
 [6]: https://vagrantcloud.com/hashicorp/precise32/version/1/provider/virtualbox.box
 [7]: https://www.virtualbox.org/manual/ch08.html
 [8]: https://en.wikipedia.org/wiki/X86_virtualization
 [9]: http://docs.vagrantup.com/v2/boxes.html
 [10]: https://en.wikipedia.org/wiki/Environment_variable
 [11]: http://msdn.microsoft.com/en-us/library/windows/desktop/bb776899%28v=vs.85%29.aspx
 [12]: http://www.vagrantup.com/blog/feature-preview-vagrant-1-6-global-status.html
 [13]: http://answers.microsoft.com/en-us/windows/forum/windows_7-desktop/change-the-default-location-of-userprofile-move/dd5a0720-909e-4b71-b665-ba8af19a104f
 [14]: https://en.wikipedia.org/wiki/Usage_share_of_operating_systems
 [15]: https://en.wikipedia.org/wiki/SecureCRT
 [16]: http://www.netsarang.com/download/down_xsh.html
 [17]: http://www.chiark.greenend.org.uk/~sgtatham/
 [18]: http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html
 [19]: https://github.com/nickryand/vagrant-multi-putty
 [20]: https://github.com/nickryand/vagrant-multi-putty/pull/9
 [21]: https://en.wikipedia.org/wiki/Eric_S._Raymond
 [22]: http://catb.org/~esr/faqs/smart-questions.html
 [23]: http://www.chiark.greenend.org.uk/~sgtatham/bugs.html
 [24]: http://www.chiark.greenend.org.uk/~sgtatham/bugs-cn.html
 [25]: https://en.wikipedia.org/wiki/PATH_%28variable%29
 [26]: http://the.earth.li/~sgtatham/putty/latest/x86/putty.zip
 [27]: http://www.cnbeta.com/articles/171116.htm
