---
layout: post
title: Vagrantfile - 从单机到集群
author: kc
tags:
- vagrant
- vagrantfile
wordpress_id: 528
wordpress_url: http://kaiwangchen.com/blog/?p=528
date: 2014-06-29 19:01:02 +0800
---

## 最简配置解读

Vagrantfile 是实验环境定义文件，`vagrant up` 根据该文件创建相同的实验环境。 `vagrant init` 产生的内容就是最简的 Vagrantfile ，去掉里面的大量注释，剩下的是

    VAGRANTFILE_API_VERSION = "2"
    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|   # Config.run("2", block)
      config.vm.box = "hashicorp/precise32"
    end
    

这四行有些奇怪的配置语句是 Ruby 代码，Vagrant 没有重新发明配置解析器，而是在沙箱里直接执行配置文件，获得需要的配置对象<!--more-->。

第一行定义一个变量表示最新的 [V2 配置格式][1]，第二至四行表示调用 [Vagrant.configure][2] 函数来产生虚拟机配置，其中 config 代表配置对象，也就是说最简配置只需指出项目虚拟机将基于名称为 [hashicorp/precise32 的镜像文件][3]创建。需要注意的是，配置对象是可以在第二行右端自由命名的，只需要保证在第三行引用相同的名字即可。实际上，这里用到 Ruby 匿名回调函数定义语法 `do |x| ... end` ，等价于 `{|x| ...}`，其中 `x` 表示回调形参，这个匿名回调由 `Vagrant.configure("2", cb)` 进行注册。推荐阅读 [Ruby From Other Languages][4] 快速了解 Ruby 语言。

每个实验环境虚拟机的最终配置实际上最多会由缺省值、VAGRANT_HOME/Vagrantfile、 VAGRANT_ROOT/Vagrantfile 、镜像附带 Vagrantfile 和 provider override 共五个部分按先后顺序依次合并产生。这里使用了 VAGRANT_HOME 和 VAGRANT_ROOT 以方便说明问题，实际配置中需展开为相应的目录，其具体定义见《[Vagrant 状态][5]》的说明。

可以参考官方手册中的 [config.vm][6] 和 [config.ssh][7] 了解更多配置项。

## 缺省配置项

把散落在 [vm.rb][8], [ssh.rb][9]:ssh_info, [provider.rb][10]:ssh_info 和 [machine.rb][11]:ssh_info 的缺省配置汇总一下，主要是以下这些项

    # 把宿主机上包含 Vagrantfile 的工作目录映射为虚拟机中的 /vagrant 目录
    config.vm.synced_folder ".", "/vagrant"
    # 把宿主机上的 2222 端口映射为虚拟机的 22 端口，同时限定 2222 端口只能宿主机本机访问
    config.vm.network "forwarded_port", guest: 22, host: 2222, host_ip: "127.0.0.1"
    # 端口映射时若发现和宿主机已用端口冲突，则在这个范围内试探出可用端口
    config.vm.usable_port_range 2200..2250
    # 若虚拟机启动过程超过 5 分钟，则 vagrant 认为虚拟机异常
    config.vm.boot_timeout = 300
    # 检查镜像文件是不是最新的
    config.vm.box_check_update = true
    # 以 Headless 模式启动 VirtualBox 虚拟机进程，即不显示虚拟屏幕
    config.vm.provider "virtualbox" do
      vb.gui = false
    done
    # ssh 私钥的路径，VAGRANT_HOME 见下文环境变量说明
    # insecure_key 是 Vagrant 官方镜像中 ssh 认证密钥对的私钥，
    # 该密钥对是随代码发布的，安装在 Vagrant\embedded\gems\gems\vagrant-1.6.3\keys\
    # 会被自动拷入 VAGRANT_HOME 中
    config.ssh.private_key_path = "VAGRANT_HOME\insecure_key"
    # 其他 ssh 连接参数
    config.ssh.guest_port = 22
    config.ssh.port = 2222
    config.ssh.host = "127.0.0.1"
    config.ssh.user_name = "vagrant"
    

## 定义虚拟机规格

一般来说，镜像制作时会采用最小虚拟机配置，Vagrant 支持在虚拟机启动前进行CPU、内存等配置。具体配置方式因虚拟机管理器而不同，VirtualBox 虚拟机可以采用这种方式：

    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 2
    end
    

或者，更自由地在虚拟机启动前使用 VBoxManage 命令进行配置：

    config.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    end
    

VirtualBox 配置项可以查阅[这里][12]或者[相关源代码][13] ，VBoxManage 命令可以参考 [VirtualBox 官方手册第八章][14]。

## 集群环境

到此为止，都假设实验环境只有一台虚拟机，实际上，我们经常需要多台虚拟机构成的集群。Vagrant 实验环境方可称为“桌面云”，自然是要支持快速创建和释放[多台虚拟机][15]的。单台虚拟机可以直接使用 config.vm 全局配置，集群配置则需用 config.vm.define 来定义多个节点，需要说明的是 config.vm.define 也是暴露虚拟机配置对象给回调函数，其配置项和 config.vm 中的是完全一样的，但 config.vm.define 定义的虚拟机可以继承全局配置项，无需重复定义相同内容。

当然，光有几台虚拟机是不能构成集群的，这些虚拟机必须网络互通，而且遵守集群部属约定。关于集群环境的典型结构，推荐阅读淘宝技术部曾宪杰的《大型网站系统与 Java 中间件实践》。简单地说，成熟的集群都会有中控节点负责监听和通知拓扑变化，其他节点只需要知道中控节点位置，注册自身服务，发现其他服务。在这种情况下，集群部属时需要约定中控节点的 IP 地址，为了保证中控节点可用性，一般需要部署多个备用节点，这些冗余节点之间也需要互相知道 IP 地址。集群 IP 地址的分配，可以在 DHCP 服务里绑定，也可以用 Puppet 等配置工具来设定，或者预设每个节点的 IP 地址，然后在应用层配置中注明集群中控节点 IP 地址。

虚拟机管理器，英文名 Hypovisor ，在 Vagrant 中称为 provider ，负责管理虚拟网络。VirtualBox 主要支持四种网络 NAT, bridged, internal network 和 host only ，相关说明详见 [VirtualBox 官方手册第六章][16]。Vagrant 支持 NAT, bridged 和 private_network （VirtualBox host only），并要求虚拟机的第一块网卡是 NAT 模式（用于映射端口以支持宿主机 `vagrant ssh` 访问），更多网卡可以用 config.vm.network 配置命令来定义。和生产环境类比的话，第一块网卡相当于接入运维网络，其他网卡则相当于接入业务网络。

    # 增加一块 dhcp 方式配置地址的网卡
    config.vm.network "private_network", type: "dhcp"
    
    # 增加一块分配静态地址的网卡
    config.vm.network "private_network", ip: "192.168.50.4"
    

下面这段代码定义了两个不同角色的虚拟机，虚拟机启动后都会执行预定义的 shell 命令。

    Vagrant.configure("2") do |config|
      # 这个配置项会被后面两个虚拟机继承
      # 注意 provision.sh 不是绝对路径，则相对于 Vagrantfile 所在的目录
      config.vm.provision "shell", path: "provision.sh"
    
      config.vm.define "web" do |web| 
        web.vm.box = "apache"
        web.vm.network "private_network", ip: "192.168.50.3"
      end
    
      config.vm.define "db" do |db|
        db.vm.box = "mysql"
        db.vm.network "private_network", ip: "192.168.50.4"
      end
    end
    

## 集群虚拟机的登陆

集群环境变复杂了，那么如何登陆虚拟机呢？还记得《[Vagrant 初印象][17]》提过过的 vagrant-multi-putty 插件吧， Windows 用户就靠它了：

    vagrant putty web # 登陆名为 web 的虚拟机
    vagrant putty db  # 登陆名为 db 的虚拟机
    

而其他操作系统的用户，把上述命令中的 putty 改成 ssh 即可。

顺便说一句，在集群生产环境中，处理一般问题是不提倡登陆主机的，而应该采用实时的集中式日志系统来支持分布式调试，如 [LogStash][18] 配合 [ElasticSearch][19] ，或者阿里云的 [Simple Log Service][20] 服务，二者都支持将日志导出到大数据分析系统，进行关联分析。

 [1]: http://docs.vagrantup.com/v2/vagrantfile/index.html
 [2]: https://github.com/mitchellh/vagrant/blob/master/lib/vagrant.rb#L137
 [3]: https://vagrantcloud.com/hashicorp/precise32
 [4]: https://www.ruby-lang.org/en/documentation/ruby-from-other-languages/
 [5]: vagrant-state.html
 [6]: http://docs.vagrantup.com/v2/vagrantfile/machine_settings.html
 [7]: http://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
 [8]: https://github.com/mitchellh/vagrant/blob/master/plugins/kernel_v2/config/vm.rb
 [9]: https://github.com/mitchellh/vagrant/blob/master/plugins/kernel_v2/config/ssh.rb
 [10]: https://github.com/mitchellh/vagrant/blob/master/plugins/providers/virtualbox/provider.rb
 [11]: https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/machine.rb
 [12]: http://docs.vagrantup.com/v2/virtualbox/configuration.html
 [13]: https://github.com/mitchellh/vagrant/blob/master/plugins/providers/virtualbox/config.rb
 [14]: https://www.virtualbox.org/manual/ch08.html
 [15]: http://docs.vagrantup.com/v2/multi-machine/index.html
 [16]: http://www.virtualbox.org/manual/ch06.html
 [17]: vagrant-putty.html
 [18]: http://logstash.net/
 [19]: http://www.elasticsearch.org/
 [20]: http://slsweb.aliyun-inc.com/
