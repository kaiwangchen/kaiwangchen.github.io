---
layout: post
title: Vagrant 数据状态浅析
author: kc
tags:
- vagrant
wordpress_id: 535
wordpress_url: http://kaiwangchen.com/blog/?p=535
date: 2014-06-29 19:20:26 +0800
---
Vagrant 给用明白了，除了怎么配置外，还需要了解其数据状态。首先介绍一些重要的环境变量，因为它们是 Vagrant 状态的概览：

    VAGRANT_HOME              USERPROFILE/.vagrant.d
    VAGRANT_CWD               项目目录
    VAGRANT_EXECUTABLE        Vagrant/embedded/gems/gems/vagrant-1.6.3/bin/vagrant
    VAGRANT_SERVER_URL        https://vagrantcloud.com
    VAGRANT_VAGRANTFILE       Vagrantfile
    VAGRANT_DOTFILE_PATH      VAGRANT_CWD/.vagrant
    VAGRANT_LOG               info
    VAGRANT_DEFAULT_PROVIDER  ""  即 virtualbox
    

Vagrant 的状态分为两种，一种是全局的，比如 box 文件、第三方插件、虚拟机信息索引等，还有一些外部状态如 VirtualBox 虚拟机池和 box 资源服务器；另一种是项目的，如实验环境虚拟机的端口映射、共享目录等定义。<!--more-->

Vagrant 全局状态目录会在第一次执行 vagrant 命令时产生

    D:\kc\.vagrant.d            // VAGRANT_HOME
      setup_version             // 目录结构版本 environment.rb:setup_home_path
      insecure_private_key      // 官方镜像密钥对私钥
      insecure_private_key.ppk  // 手工转换的 PuTTY 格式私钥
      plugins.json              // vagrant plugin 注册表
      boxes                     // Vagrant 本地镜像目录
        hashicorp-VAGRANTSLASH-precise32  // box name
          metadata_url          // https://vagrantcloud.com/hashicorp/precise32
          1.0.0                 // box version
            virtualbox          // provider
              box.ovf
              box-disk1.vmdk
              metadata.json     // {"provider":"virtualbox"}
              Vagrantfile       // config.vm.base_mac = "080027129698"
      data
        machine-index
          index                 // machines json: share folder, machine name, provider,
                                //   power state, vagrantfile directory, box name
          index.lock 
    
      gems                      // plugins build and code
      tmp
    

因为 Vagrant 只是包装了 VirtualBox ，实际上虚拟机还是归 VirtualBox 负责的。Vagrant 充分利用虚拟机快照功能，在创建虚拟机的时候，是基于镜像磁盘快照，而不是复制磁盘，这样一方面可以节省硬盘空间，另一方面创建速度也会快一些。

    D:\kc\VirtualBox_VMs
      precise32
        box-disk1.vmdk           // 986MB box disk
      vagrant_example_default_1404007888602_57131
        vagrant_example_default_1404007888602_57131.box  // precise32 的磁盘快照
        Logs
          Vbox.log
    

在 `vagrant init` 后，项目目录中产生 Vagrantfile 文件，这也是一个空项目的初始状态

    D:\kc\vagrant_example       // VAGRNAT_CWD 或称 root
      Vagrantfile               // VAGRANT_VAGRANTFILE 配置文件
    

在 `vagrant up` 后，产生该项目实验环境的虚拟机状态

    D:\kc\vagrant_example
      Vagrantfile                // 本项目的实验环境定义
      .vagrant                   // 本项目的虚拟机状态
        machines                 // environment.rb:active_machines
          default                // machine
            virtualbox           // provider
              action_provision
              action_set_name
              id                 // VirtualBox uuid
              index_uuid
              synced_folders     // 虚拟机-宿主机 目录映射关系
