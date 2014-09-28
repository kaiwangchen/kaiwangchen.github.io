---
layout: post
title: Vagrant 镜像制作与共享
author: kc
tags:
- vagrant
wordpress_id: 637
wordpress_url: http://kaiwangchen.com/blog/?p=637
date: 2014-07-14 21:17:18 +0800
---

## 镜像制作

有三种方式可以生成镜像文件：

1.  将本地仓库中的镜像重新打包。由于只需要本地仓库，跟 Vagrant 项目没关系，这个命令不必在项目目录下，也不需要停任何虚拟机：`vagrant repackage`
2.  将一个 Vagrant 项目的虚拟机重新打包。这是基于某个项目的修改，需要停止该项目虚拟机并到该项目下执行命令：`vagrant package` 
3.  从头开始制作一个新的镜像

事实上，万能的开源社区已经打造了一个强大的镜像制作工具 [VeeWee][1] ，支持[定制虚拟机模板][2]，自动安装系统并打包产生镜像。但无论如何，工具只是重复手工劳动的替代品，虽然已经省事，但要用得明白，所以还是需要了解一些内幕，比如镜像文件格式和虚拟机约定。<!--more-->

### 镜像文件格式

镜像文件只不过是一个伪装成 .box 、多塞入两个描述文件的 [OVA][3] 包而已，打包格式是 [tar][4] 并可能启用了 gzip 压缩。约定的目录结构是

    $ tar ztf package.box
    ./box-disk1.vmdk      # 虚拟机的磁盘文件
    ./box.ovf             # OVF 描述文件，在这里定义虚拟机规格并引用磁盘文件
    ./Vagrantfile         # 可能包含一些镜像相关的配置
    ./metadata.json       # {"provider":"virtualbox"}
    

所谓的 OVA 就是 OVF 描述文件和它引用的虚拟磁盘文件合起来的 tar 包。考虑到不便从 OVF 描述文件中判断该虚拟机的管理器，还需要支持容器虚拟化技术， Vagrant 增加了一个 `metadata.json` 来跟踪虚拟机管理器。随镜像附带的 Vagrantfile 在不同管理器之间共享一段配置提供了方便，也可以预置一些镜像相关的项。

### 虚拟机约定

毫无疑问， Vagrant 的便利性需要虚拟机实例遵守一些约定（第 3 和 4 项假设 Linux 或者 Cygwin Windows ，若是 rdp Windows ，可以参考[这里][5]）：

1.  尽量裁剪系统，去掉音频和 USB 等没用的部件，减少虚拟磁盘和镜像的大小
2.  虚拟机用最低配置，因为 Vagrant 支持在虚拟机启动前修改配置
3.  虚拟机必须提供支持公钥登陆的 SSH 服务，且预装 SSH 公钥到 `config.ssh.username` 约定的 SSH 帐号下（默认是 `vagrant` ），而宿主机上相应的私钥位置则由 `config.ssh.private_key_path` 指定，默认是 `VAGRANT_HOME/insecure_private_key`
4.  这个 SSH 帐号必须拥有无密码 sudo ALL 权限，用于虚拟机启动后登入执行改主机名、provision 等操作
5.  虚拟机中必须安装 [VirtualBox Guest Additions][6] ，用于支持目录共享，因为 provision 配置和项目代码都是在共享目录中的
6.  删除一些捣乱的 udev 记录
    
    $ rm /etc/udev/rules.d/70-persistent-net.rules $ mkdir /etc/udev/rules.d/70-persistent-net.rules $ rm -rf /dev/.udev/ $ rm /lib/udev/rules.d/75-persistent-net-generator.rules

如果 3 中采用默认帐号和官方公开密钥对的话，那么虚拟机中的操作是：

    $ mkdir /home/vagrant/.ssh
    $ chmod 700 /home/vagrant/.ssh
    $ cd /home/vagrant/.ssh
    $ curl -o authorized_keys \
        'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' 
    $ chmod 600 /home/vagrant/.ssh/authorized_keys
    $ chown -R vagrant /home/vagrant/.ssh
    

如果采用了自定义的账号，那么最好在随镜像附带的 Vagrantfile 中注明。

然后关闭虚拟机，执行下面的命令打包

    vagrant package --base VirtualBoxGUI中显示的虚拟机名 [--vagrantfile 预置帐号的配置文件]
    

## 镜像仓库

制作完镜像，是时候分享了。

从使用者角度看， vagrant 会先查找本地仓库 `VAGRANT_HOME/boxes` 中是否有给定的镜像文件，没有的话就尝试下载远程镜像。此外，如果虚拟机是从远程镜像产生，那么 `vagrant box outdated` 命令会立即检查远程镜像是否有新版本，或者，在缺省配置下 `config.vm.box_check_update = 1` ，`vagrant up` 启动虚拟机时也会检查新版本。不过，检查版本并不会下载更新，而是需要 `vagrant box update` 来执行操作。

在获取镜像时，按 box_url 的不同风格，有不同的行为

    box_url    示例                 行为
    
    shorthand  hashicorp/precise64  用 VAGRANT_SERVER_URL 补全的镜像路径
                                    如 https://vagrantcloud/hashicorp/precise64
    name       centos65             项目目录下的镜像
    file://                         本地镜像路径
    http(s)://                      远程镜像路径
    

注意，只有镜像命名为 *shorthand* 方式，即 `hashicorp/precise64` 这种没有明确指定协议且名字中间带 / 字符的情况，才会从 `VAGRANT_SERVER_URL` 定义的远程仓库中查找。但不论是 shorthand 方式还是明确指定路径，最终都会获得一个镜像 URL ，然后可能有两种情况：这个 URL 指向镜像元数据文件，或者，指向镜像文件本身。

*镜像元数据*是本地 JSON 文件或者 application/json 格式的 HTTP 响应，由 [box_metadata.rb][7] 负责解析。若元数据是磁盘中的 JSON 文件，vagrant 会尝试用 JSON 解析器加载文件；完整的元数据请求响应交互，则可以参考[这里][8]。镜像元数据 JSON 内容说明如下：

    {
       "description": "...",                         # 必选，较长的镜像介绍
       "short_description": "...",                   # 简短的介绍
       "name": "owner/box"                           # 必选， shorthand 镜像名
       "versions": [
         {
           "version": "x.y.z",                       # 必选，版本号
           "status": "active",
           "description_html": "...",                # 格式的版本说明
           "description_markdown": "...",            # MarkDown 格式的版本说明
           "providers": [
             {
                "name": "virtualbox",                # 必选，虚拟机管理器
                "url": "https://..."                 # 必选，镜像文件的完整路径
                "checksum": "..."
                "checksum_type": "MD5|SHA1|SHA2"     # box_add.rb:validate_checksum
             }
           ]
         },
       ]
    }
    

那么，远程仓库的维护可以有两种方式：虽然都在远程存储按版本组织镜像，但可以由用户自行维护版本号和镜像文件路径的映射关系，或者，由镜像的元数据来维护映射关系，而用户只需要知道固定的元数据路径和镜像版本号即可。从可维护性角度看，推荐第二种方式。也就是说，

1.  镜像仓库需要支持 `application/json` 格式响应 `VAGRANT_SERVER_URL/owner/box` 元数据请求
2.  镜像仓库需要提供文件下载
3.  用户设定 `VAGRANT_SERVER_URL` 指向镜像仓库根路径，然后 `vagrant init owner/box` 即可引用镜像

让我们来回顾一下最初的设想：用户可以迅速获得一个环境，方便地在不同环境之间切换，完全不用担心环境维护，一切都在版本控制系统中。这，就是 Vagrant 带来的变革，它不仅仅是一个工具。

 [1]: https://github.com/jedi4ever/veewee
 [2]: https://github.com/jedi4ever/veewee/blob/master/doc/customize.md
 [3]: http://en.wikipedia.org/wiki/Open_Virtualization_Format
 [4]: http://en.wikipedia.org/wiki/Tar_%28computing%29
 [5]: http://dennypc.wordpress.com/2014/06/09/creating-a-windows-box-with-vagrant-1-6/
 [6]: https://www.virtualbox.org/manual/ch04.html
 [7]: https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/box_metadata.rb
 [8]: http://kaiwangchen.com/blog/wp-content/uploads/2014/07/vagrant_box_metadata.txt
