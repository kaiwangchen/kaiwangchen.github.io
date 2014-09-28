---
layout: post
title: 在 Windows 上用 Eclipse + CDT 远程调试 Linux 进程
author: kc
tags:
- eclipse
- cdt
- gdbserver
- cross debugging
wordpress_id: 600
wordpress_url: http://kaiwangchen.com/blog/?p=600
date: 2014-07-12 16:36:49 +0800
---

作为一个铁杆 [VIM][1] 用户，哥是不太用[集成开发环境 IDE][2] 的。并非因为不知道或者不会使用，只是觉得这些东西虽然可以提高开发速度，但催生了一大票对程序环境理解颇为肤浅的开发人员，造成了各种开发过程和生产环境问题，有点令人讨厌。而 IDE 自有其便利之处，程序调试就是一例。

Eclipse 由于其开源、跨平台，以及各种语言和开发环境支持，俨然已经是开发者首选的 IDE 工具。不过据说 Google Android 标准开发环境放弃 Eclipse 转向神器 [IntelliJ][3] ，[消息][4]利好利空，请自行把握。本文介绍在 Windows 系统上用 Eclipse + CDT 调试 CentOS 6.5 上的 tengine-2.0.3 服务进程。

**注：应该还有更方便的基于 SSH 通道的调试方式，暂未深入了解。**

## 总体介绍

整个环境简单概括为：宿主机 Windows 系统上的 Eclipse + CDT 工具，支持交叉调试的 gdb 版本，当然还有 [tengine-2.0.3][5] 代码树和编译结果。虚拟机 Linux 系统上的 tengine-2.0.3 代码树及编译环境、编译出来的 nginx 可执行程序和用于支持远程调试的 gdbserver 。 交叉调试工具 gdb 会读取 Linux 编译结果中的符号，通过 [gdb 远程协议][6]与 [gdbserver][7] 通信，这个通信协议中会有一些 XML 格式的数据。<!--more-->

鉴于 Eclipse + CDT 环境可以直接从官网下载，而 Linux 上安装和编译程序非常方便，那么，关键问题就只剩下交叉调试工具怎么获得，又如何在 Eclipse 中进行设置。完整的过程是：

1.  Windows 和 Linux 之间的文件共享和网络互通
2.  在 Linux 上编译带调试符号的 tengine
3.  在 Linux 上安装 gdbserver 并测试远程调试
4.  在 Windows 上用 [MinGW][8] gcc 来编译能够识别 Linux 可执行文件的 gdb 版本，并确保远程调试如期工作
5.  将代码树导入 Eclipse + CDT 环境，设置远程调试参数

## 1 Windows 和 Linux 之间的数据共享和网络互通

数据共享的方式有多种。本文采用的是在 VirtualBox 虚拟机中运行 Linux ，采用共享目录的方式来共享代码树和编译结果。在开发虚拟机的维护上使用了 Vagrant 工具。如果对 Vagrant 不熟，那可参阅前面《Vagrant – 实验环境总管》和《Vagrantfile - 从单机到集群》等系列文章。这个工具实在是太有用了，强烈推荐！

Vagrant 默认会映射配置文件 Vagrantfile 所在项目目录到虚拟机系统中的 `/vagrant` 目录，将虚拟机 22 端口映射到宿主机 2222 端口。为了支持远程调试，还需要将虚拟机 Linux 中的 gdbserver 3456 端口映射到宿主机 Windows 的 3457 端口，这两个端口可以随意选定的，互不冲突。由于 CentOS 防火墙默认只打开了 22 端口，需要打开 gdbserver 端口，或者关闭防火墙。支持这个部署的 Vagrantfile 内容是

    VAGRANTFILE_API_VERSION = "2"
    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      config.vm.box = "centos65"
      config.vm.network "forwarded_port", guest: 3456, host: 3457
      config.vm.provision "shell", inline: "sudo /etc/init.d/iptables stop"
    end
    

注意上面引用了 centos65 自制镜像，怎么制作镜像请参考《Vagrant 镜像制作与共享》，或者，可以直接引用 HashiCorp 官方的 [hashicorp/precise64 镜像][9] ，但 precise64 镜像中是 Debian 系的 Ubuntu 位系统，用的是 apt 包管理系统，而 RedHat 系的 CentOS 系统用的是 yum 包管理系统，所以，下文中安装包的命令不再适用，还请自行修改命令。

其他环境下可能需要用 Samba 来共享代码树，或者通过版本控制仓库获得相同的代码树。

## 2 在 Linux 上编译带调试符号的 tengine

先安装编译环境和 tengine 依赖库 pcre 和 openssl 的头文件。大概就这么多，有需要的话再补上吧。

    $ sudo yum install gcc make pcre-devel openssl-devel
    $ sudo rpm -qa | grep -e gcc -e make -e pcre-devel -e openssl-devel
    gcc-4.4.7-4.el6.x86_64
    pcre-devel-7.8-6.el6.x86_64
    make-3.81-20.el6.x86_64
    libgcc-4.4.7-4.el6.x86_64
    openssl-devel-1.0.1e-16.el6_5.14.x86_64
    

然后下载 `tengine-2.0.3` 代码包，编译并安装到共享目录 `/vagrant`

    $ curl ttp://tengine.taobao.org/download/tengine-2.0.3.tar.gz | tar zxf -
    $ cd tengine-2.0.3
    $ ./configure --prefix=/vagrant/tengine
    $ make CFLAGS="-g -O0"  # 保留调试符号，关闭编译优化
    $ make install
    

然后测试编译结果是否可以正常工作

    $ sudo ./nginx -g 'daemon off; master_process off;'
    $ curl http://localhost  # 需在另一个终端下执行测试
    

注意 `nginx -g` 表示用[命令行参数][10]定义全局配置项，[Nginx 配置指令][11] `daemon off` 关闭守护进程模式， `master_process off` 关闭主进程模式，都是为了方便调试。

## 3 安装 gdbserver 并测试远程调试

    $ sudo yum install gdb-gdbserver
    $ cd /vagrant/tengine/sbin
    $ sudo gdbserver :3456 ./nginx -g 'daemon off; master_process off;'
    

然后在另一个终端

    $ gdb -d /vagrant/tengine-2.0.3 ./nginx
    Reading symbols from /vagrant/tengine/sbin/nginx...done.
    (gdb) target remote 127.0.0.1:3456
    Remote debugging using 127.0.0.1:3456
    Reading symbols from /lib64/ld-linux-x86-64.so.2...(no debugging symbols found)...done.
    Loaded symbols for /lib64/ld-linux-x86-64.so.2
    0x00007f8695254b00 in _start () from /lib64/ld-linux-x86-64.so.2
    Created trace state variable $trace_timestamp for target's variable 1.
    Missing separate debuginfos, use: debuginfo-install glibc-2.12-1.132.el6_5.2.x86_64
    (gdb) b main
    Breakpoint 1 at 0x40f5ca: file src/core/nginx.c, line 213.
    
    $ c
    Continuing.
    warning: Could not load shared  library symbols for 18 libraries, e.g. ...
    Use the "info sharedlibrary" command to see the complete listing.
    Do you need "set solib-search-path" or "set sysroot"?
    
    Breakpoint 1, main (argc=3, argv=0x7fff72ee6928) at src/core/nginx.c:213
    213         if (ngx_strerror_init() != NGX_OK) {
    (gdb) quit
    

注意这里用了 `gdb -d` 命令行参数指定源代码目录，和 `(gdb)` 命令提示符下用 `directory /vagrant/tengine-2.0.3` 是一个效果。关于 gdb 使用，可以参考 [GDB 官方手册][12]。

## 4 在 Windows 上用 MinGW gcc 来编译能够识别 Linux 可执行文件的 gdb 版本

不得不说这是最坑爹的一步。相信很多人对 MinGW 包管理都不熟，而且可用的包也不多。 好在 MinGW 在线安装还算方便，先去[官网][8]右上角找到 Installer 下载按钮，下载打开 Installer 然后选中需要安装的包就可以了。MinGW 环境有三个比较重要的东西：

1.  libexec/mingw-get/guimain.exe 图形界面的包管理工具
2.  msys/1.0/ MinGW环境的根文件系统
3.  msys/1.0/msys.bat MinGW 环境的命令行入口，/home/kc 即是 msys/1.0/home/kc

在 MinGW 环境中可以用 d:/repo/tengine-2.0.4/ 方式来访问宿主机文件。

[支持远程调试的 gdb][13] 需要 mingw32-libexpat 的 dev 包（即头文件）。编译时虽然检测不到 expat 也是能通过的，但编出来的 gdb 不能完整支持远程调试协议。那不是残废么。。重新编译一遍又要等半天。可以用 `--with-expat` 强制依赖 expat 包，若不满足条件则在 `make` 时会报错。

双击 msys.bat 进入 MinGW 命令行，处于家目录下。

    curl http://ftp.gnu.org/gnu/gdb/gdb-7.7.1.tar.gz -o gdb-7.7.1.tar.gz
    tar zxf gdb-7.6.1.tar.gz
    cd gdb-7.6.1
    ./configure --target=x86_64-pc-linux-gnu --with-expat
    make 
    

编译结果在 `msys/1.0/home/kc/gdb-7.6.1/gdb/gdb.exe` ，这个路径后面会用到。

对于交叉调试工具的编译而言，会涉及三个环境，一个是编译环境 build ，另一个是工具本身的运行环境 host ，还有一个是工具处理的目标对象的运行环境 target ，上面的 `--target=x86_64-pc-linux-gnu` 表示 gdb 要支持 GNU/Linux x86_64 环境下的可执行文件格式。如果不确定 Linux 环境，那 `uname -i` 一下，把输出架构替换掉 target 串中的 `x86_64` 。 build 和 host 会由 configure 脚本自动检测。

现在像第 2 步中一样，测试交叉调试 gdb 是否能如期工作。先在 Linux 环境中用 gdbserver 启动 nginx 进程

    $ sudo gdbserver :3456 ./nginx -g 'daemon off; master_process off;'
    

然后在 MinGW 命令行中执行测试

    gdb d:/repo/tengine/sbin/nginx
    (gdb) target remote 127.0.0.1:3457
    

要有和第 2 步几乎相同的输出。

## 5 在 Linux 和 Windows 之间共享 tengine 代码树，将代码树导入 Eclipse + CDT 环境，设置远程调试参数

先到 Java 官网下载最新的 [JDK 8u5][14] 。似乎时代进步了，无需设定 JAVA_HOME 环境变量，这是个好消息。然后到 Eclipse 官网下载 [Eclipse IDE for C/C++ Developers 打包版][15]， Eclipse + CDT 环境就具备了。

到安装目录找到 eclipse.exe 双击打开，workspace 好像没什么用，选个合适的目录就行。在 "New | Makefile project with exising code" 后指定项目为 D:\repo\tengine-2.0.3 ，选 "Toolchain for Indexer Settings " ，确定后导入源代码树到 tengine-2.0.3 项目。

然后在 "Run | Debug Configurations | C/C++ Remote Application" 下新建调试配置

    Main tab:
    C/C++ Application D:\repo\gs\tengine\sbin\nginx
    Disable auto build
    Using GDB (DSF) Manual Remote Debugging Launcher - Select other...
    
    Debugger tab | Main tab:
    GDB debugger D:\MinGW\msys\1.0\home\kc\gdb-7.7.1\gdb\gdb.exe
    DEbugger tab | Connection tab:
    localhost 3457
    

注意一定要选 GDB 手工模式，不然自动下载可执行文件，而由于目录共享方式，下载源和目标存储是同一个文件，会造成可执行文件变为 0 长度，下载也会卡死。然后进入 Linux 启动 gdbserver ，回到 Eclipse 下从 tengine-2.0.3-linux 调试配置开始调试。

话说 Eclipse 默认的调试界面布局不太友好，个人比较喜欢两列风格，小屏幕上看代码也不至于太憋屈。 Source, Debug, 和 Variables 是必须的，其他的有需要再从页签调出，效果如下：

![cdt-gdbserver][16]

p.s. 开始准备环境时参考了[这篇文章][17] ，在此表示感谢。

 [1]: http://www.vim.org
 [2]: http://zh.wikipedia.org/wiki/%E9%9B%86%E6%88%90%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83
 [3]: http://www.jetbrains.com/idea/
 [4]: http://techblog.youdao.com/?p=617
 [5]: http://tengine.taobao.org/download_cn.html
 [6]: http://sourceware.org/gdb/onlinedocs/gdb/Remote-Protocol.html
 [7]: http://en.wikipedia.org/wiki/Gdbserver
 [8]: http://www.mingw.org/
 [9]: https://vagrantcloud.com/hashicorp/precise32
 [10]: http://wiki.nginx.org/NginxCommandLine
 [11]: http://nginx.org/en/docs/dirindex.html
 [12]: https://sourceware.org/gdb/current/onlinedocs/gdb/
 [13]: http://stackoverflow.com/questions/5665800/compiling-gdb-for-remote-debugging
 [14]: http://www.oracle.com/technetwork/java/javase/downloads/index.html
 [15]: http://eclipse.org/downloads/
 [16]: {{ site.fileurl }}/2014/07/cdt-gdbserver.png
 [17]: http://blog.csdn.net/keepliving/article/details/6632612
