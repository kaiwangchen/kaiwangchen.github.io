---
layout: post
title: Vagrant - 实验环境总管
author: kc
tags:
- vagrant
- desktop cloud
- devops
wordpress_id: 470
wordpress_url: http://kaiwangchen.com/blog/?p=470
date: 2014-06-22 19:21:46 +0800
---

tack][2] 能够在单机上运行，但集群的“[部分失效][3]”场景已不复存在。系统管理员则要么直接在生产环境上拼人品，要么也得起一套模拟环境。

有什么办法能够让大家不受干扰地测试新功能，而且相信它会在生产环境也一样表现吗？在这 [DevOps][4] 横行的年代，复制一套生产环境已经不再是难事，即使在一台普通的笔记本上。如果你不知道 [Vagrant][5] ，那你已经 out 了！<!--more-->

不论是新人还是老员工，不论用的是高大上 Mac Book Pro 还是屌丝 Thinkpad ，有 Vagrant 在手，只需检出项目，[一行命令][6]，两三分钟，就可以获得一个与生产环境几乎完全相同的开发测试环境。虽然[配置管理][7]才是环境复制的幕后功臣，但 Vagrant 将这一切[带到了开发机][8]。显然，开发机得足够强劲，支持虚拟机集群的流畅运行，而这通常不是问题，主流笔记本性能已经堪比昨天的服务器，就算真跑不动也无所谓，Vagrant 还[支持 Amazon EC2][9] 哦。

## 软件的运行环境

既然是谈环境搭建，那就有必要先了解一下环境构成。常规应用软件的环境构成，大致可以分为高级语言、低级语言、操作系统及网络三个层面，若是在虚拟化环境里，那还增加了一个虚拟层，即

1.  高级语言编译环境、运行类库和高级语言虚拟机
2.  系统语言编译环境和运行类库
3.  系统容器或客户操作系统，虚拟网络
4.  物理机操作系统和物理网络

这些层的组件都在独立发展，从而演化出各自版本树，虽然大家在努力管理兼容性问题，如[语义版本管理][10]规定小版本必须兼容，但应用环境各组件的版本一直是大家头疼的事情，由此引出一系列配置管理工具，如经典的有 [CFEngine][11] 和 [Chef][12] ，新兴的有 [Puppet][13] 、 [Saltstack][14] 和以业务集群支持为特色的 [Ansible][15] ，以便给定 *一组环境定义* 和 *一个正在运行的操作系统* ，就能自动从 *各层面的软件仓库*，如 [yum 仓库][16]和 [maven 仓库][17]等，下载安装约定的软件和类库，并做好相应配置。这个安装和配置的过程称为狭义的 provisioning （[更广义的说法][18]则包含了安装操作系统在内）。一个成熟的生产环境，provision 过程必须是自动的，而软件仓库和环境定义，除了必要的升级外，其维护几乎是一劳永逸的。

至此，我们已经完成了两个层面的工作，而要形成完整的软件环境，还需要一些基础工作：安装操作系统，并在启动后触发 provisioning 。操作系统的安装无非是检测硬件环境，格式化硬盘和文件系统，然后复制文件。以 Redhat Linux 发行版为例，[anaconda][19] 已早已做好了定义文件和安装过程的分离，对于同一个[定义文件][20]，总能从空盘开始产生出相同的操作系统。这个过程虽然是自动的，却也需要消耗一些时间，所以镜像方式也不乏市场。

所谓的[镜像][21]方式，即不再是从空盘开始复制，而是将原先安装好的操作系统导出到一个称为镜像 image 的文件，安装新主机时就直接将该镜像展开到目标空间，从而避免了冗长的安装过程。镜像技术有很多，如[硬盘克隆][22]，文件系统转储 [xfsdump][23] ，对于虚拟化环境，则通常有制作好的镜像文件供大家下载，其格式因虚拟化技术而异。镜像方式的潜在问题是，有些东西是主机特有的，如安装过程检测的硬件环境可能和以镜像方式安装的目标主机硬件环境有差异，主机SSH密钥若共享还会带来安全问题，所以需要仔细剥离剔除，或在系统启动时重置。

至于物理设备和物理网络的处置，只好留给苦逼的 IT 现场工程师了。这听起来像是在谈神秘的生产环境，但开发环境不过是生产环境的实验版罢了，纵然手上的笔记本是多么地高大上，程序员何尝不是苦逼的 IT 现场工程师。

## 虚拟化和云计算

在这个云计算泛滥的时代，有必要提一下主机虚拟化和容器虚拟化。

主机虚拟化是指模拟出一个完整的硬件环境，涉及三个角色：[虚拟机管理器][24]，宿主机和客户机，其中宿主机是指物理机，虚拟机管理器运行于宿主机之上，而客户机则是指宿主机上运行的虚拟机。Linux 上有 [KVM][25] 和 [Xen][26] 两大虚拟机管理器， Xen 拥有往日风光，KVM 似乎渐成主流，获得了 [Redhat 的垂青][27]，并已[进驻 kernel 代码树][28]。[VirtualBox][29] 在主流操作系统上都能工作，不过主要是作为开发环境；[VMWare][30] 作为虚拟化的元老，虽然许可证很贵，但仍然不乏市场。KVM、Xen、VirtualBox 和 VMWare 虚拟出来的硬件环境和常规物理机并没有太多不同，而且由于[硬件加速技术][31]和[虚拟设备技术][32]的不断发展，性能差距也越来越小，但毕竟是重量级模拟，与[容器虚拟化][33]还是会有一些差距。

所谓的容器虚拟化，是指利用宿主机操作系统内核的隔离功能，把应用程序进程约束到容器内，和其他进程互不干扰。在 Linux 系统上，是基于一系列[名字空间][34]进行进程号、IP地址和端口、进程间通信、挂载点等资源的隔离，并用 [cgroups][35] 来控制资源用量。[时下很火][36]的 [Docker][37] 就是容器虚拟化的典型应用。

下图给出了两种虚拟化技术的比较（图片来自 2014.7.13 [docker 中文社区 meetup #2][38] 中 UCloud [邱模炯][39] 的《[container 内核原理浅谈][40]》技术分享，已获授权使用）

![virtualization.png][virtualization.png]

主机虚拟化可以支持客户机安装各种操作系统，所以 IaaS 只能采用主机虚拟化以满足租户参差不齐的操作系统需求，如[青云][41]基于 KVM ，[阿里云][42]则基于 Xen 。容器虚拟化虽然绑定了操作系统内核，但由于几乎没有性能损失，启动速度快，已经成为 PaaS 的首选。

所谓的基础设施云 [IaaS][43] ，简单地理解，就是巨大的虚拟机集群和复杂的虚拟网络，按需划分给云的租户，但租户网络是互相不通的。为了让这一切能够和谐地运行起来，就得有一套管理系统，如开源的 [OpenStack][44] 已经成为事实标准。所谓的平台云 [PaaS][45] ，简单地理解，就是还没有部署应用代码的生产环境，如 [Google GAE][46] 和 [Heroku][47] 等都是 PaaS 的经典案例。由于 IaaS 和传统基础设施非常相似，在云时代的发展初期，IaaS 自然是主流，但大家最终需要的还是生产环境，据 GAE 创始人 Randy [预测][48]，PaaS 将会在三五年后成为主流。从标准化进程来看，IaaS 属于系统和网络标准化阶段，而 PaaS 属于生产环境标准化阶段。

那 Vagrant 和这些又有什么关系？说得炫一点，Vagrant 是桌面系统上的 IaaS ，其虚拟化技术缺省情况下为 VirtualBox 。

## Vagrant 过程

开发迭代过程可分为三步：检出代码实现功能，在开发环境里测试，提交到版本控制仓库。其中，开发环境的维护有两种方式，重装操作系统和安装各种软件，从而使每次实验都基于干净的环境，或者，同一个环境多人共享反复使用。虽然存在各种干扰隐患，但仍然有很多人使用了第二种方式，究其原因无非是干净环境的成本太高。Vagrant 的诞生正是为了解决这种问题。

简单地说，任何临时变动都应该被丢弃，每次实验虚拟机都由 Vagrant 从同一个镜像产生，并经过同样的 provision 过程，从而保证每次实验都是在*相同的环境*下进行。由于维护成本降低，干净的实验环境成为标配，项目开发就不再受到环境干扰，跨项目切换也容易多了。

    $ git clone git://.../project.git
    $ cd project
    $ vagrant up
    $ vagrant putty  # ssh 登录 linux 系统，对于 Windows 系统，则用 rdp 子命令登录
    $ vagrant halt
    $ vagrant destroy
    $ git commit
    

那么，这幕后又发生了什么呢？

 [1]: http://bluedavy.me
 [2]: http://devstack.org
 [3]: http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.48.7969&rep=rep1&type=pdf
 [4]: http://www.infoq.com/cn/articles/wide-range-devops
 [5]: http://vagrantup.com
 [6]: http://docs.vagrantup.com/v2/getting-started/up.html
 [7]: https://www.usenix.org/system/files/login/articles/105457-Lueninghoener.pdf
 [8]: http://kief.com/bring-the-cloud-on-your-desktop-with-vagrant.html
 [9]: https://github.com/mitchellh/vagrant-aws
 [10]: http://semver.org/
 [11]: http://cfengine.com
 [12]: http://www.getchef.com
 [13]: http://puppetlabs.com
 [14]: http://saltstack.com
 [15]: https://github.com/ansible/ansible
 [16]: https://en.wikipedia.org/wiki/Yellow_dog_Updater,_Modified
 [17]: http://maven.apache.org
 [18]: https://en.wikipedia.org/wiki/Provisioning
 [19]: https://fedoraproject.org/wiki/Anaconda
 [20]: https://fedoraproject.org/wiki/Anaconda/Kickstart
 [21]: https://en.wikipedia.org/wiki/System_image
 [22]: https://en.wikipedia.org/wiki/Disk_cloning
 [23]: https://launchpad.net/xfsdump
 [24]: https://en.wikipedia.org/wiki/Hypervisor
 [25]: http://linux-kvm.org
 [26]: http://xenproject.org
 [27]: http://www.infoq.com/news/2008/06/redhat-kvm
 [28]: http://chucknology.com/2012/02/02/kvm-is-linux-xen-is-not/
 [29]: http://virtualboxes.org
 [30]: http://vmware.com
 [31]: https://en.wikipedia.org/wiki/Intel_VT-x#Intel-VT-x
 [32]: http://www.ibm.com/developerworks/library/l-virtio/index.html
 [33]: http://marceloneves.org/papers/pdp2013-containers.pdf
 [34]: http://lwn.net/Articles/531114/
 [35]: https://www.kernel.org/doc/Documentation/cgroups/
 [36]: http://blog.docker.com/2014/01/docker-closes-15-m-series-b-funding/
 [37]: https://docs.docker.com/introduction/understanding-docker/
 [38]: https://www.dockboard.org/docker-beijing-meetup-2-keynotes/
 [39]: https://www.dockboard.org/docker-meetup-2-speaker-qiu-mo-jiong/
 [40]: http://docker.u.qiniudn.com/container%E5%86%85%E6%A0%B8%E5%8E%9F%E7%90%86%E6%B5%85%E8%B0%88.ppt
 [41]: http://www.qingcloud.com
 [42]: http://www.aliyun.com
 [43]: https://en.wikipedia.org/wiki/Cloud_computing#Infrastructure_as_a_service_.28IaaS.29
 [44]: http://www.openstack.org/
 [45]: https://en.wikipedia.org/wiki/Platform_as_a_service
 [46]: http://developers.google.com/appengine
 [47]: http://heroku.com
 [48]: http://weibo.com/1662047260/B1el6uGyc
 [virtualization.png]: {{ site.fileurl }}/2014/06/virtualization.png
