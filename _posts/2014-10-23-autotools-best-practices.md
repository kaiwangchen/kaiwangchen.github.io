---
layout: post
title: "Autotools 最佳实践"
author: kc
tags:
- autotools
---

_本文译自 [Diego "Flameeyes" Petteno][flameeyes] 于 2005 年在 linux.com 上发表的[文章][autotools-best-practice-en] ，其年代久远不再适用之处我已于译注中努力说明。作者在大量工程实践中提炼出 [Autotools MythBuster][autotools-mythbuster] 并开源给大众，配合 Alexandre Duret-Lutz 的 [Autotools 教程][autotools-tutorial]，学习使用 autotools 的条件岂可同日而语（请扔掉那本臃肿的 [Autobook][autobook-en] ，虽然已有[中译版][autobook-cn]面世）。_

GNU 编译工具链是 GNU 系列软件包的构建工具，其核心部分被称为 [autotools][autotools] ，主要是指 autoconf 和 automake ，此外还包含 libtoolize, autoheader, pkg-config 和 gettext 。这些工具向开发者提供了一套检测程序库、函数及辅助工具的框架，使得在各种 Unix 系操作系统上编译 GNU 软件成为可能。虽然 autotools 是资深开发者手中的利器，但对于初级使用者来说，不免有点复杂，而软件包对 autotools 支持不健全的现象时有发生。本文讨论使用 autotools 的常用问题，并给出改进建议。

虽然大家对 autotools 各有看法，但毋庸置疑的是暂无可用替代品<sup>译注1</sup>。像 [Scons][scons] 这些项目的可移植性难忘 autotools 之项背，而且也鲜为大众所知。 autotools 有大量的自动检测，还有大量的程序库附带了 [m4][m4] 宏库来支持对其的检测。

> 译注1: 译此文已是 9 年后的 2014 年， [CMake][cmake] 项目风生水起，已经占领了 MySQL, LLVM, zlib 等阵地。

使用 autotools 的项目，其结构是相当简单的。 Autoconf 会读取 m4 语言编写的 configure.ac （曾为 configure.in ）文件，并借助于 aclocal.m4 宏库（aclocal 工具分析 configure.ac 中用到的宏函数，从所有宏库及 acinclude.m4 中提取定义到该文件），展开成 configure 脚本。而项目中的 Makefile.am 文件，都由 automake 生成 Makefile.in 模板，并最终由 configure 脚本处理生成 Makefile 。你完全可以避开 automake ，自己手写 Makefile.in ，但这个过程相当复杂，而且也失去了 autotools 的一些特性。

在 configure.ac 中也可以使用自定义的宏、autoconf 和 aclocal 提供的宏、以及其他软件包提供的宏。而 aclocal 则会创建 acloal.m4 文件，将所有用到的宏的定义放入其中；这是 autotools 的重要步骤，暂且按下不表。

Makefile.am 主要是一些声明：将构建目标加入到一些变量。这些变量的命名格式为 `placetoinstall_TYPEOFTARGET`<sup>译注2</sup> ，其中下划线左侧可以是 Unix 文件系统中的位置（如 bin, lib 和 include 等），或者表示任意路径的非关键字（如 x ，则可以使用  xdir 变量来定义任意安装位置），或者 `noinst` ，表示不安装该目标（例如内部头文件、构建期静态库）。然后就可以将构建目标名作为前缀（将其中的英文句号替换为下划线<sup>译注3</sup>）来定义另一组变量，它们可以影响构建行为。将构建目标名作为 CFLAGS, LDFLAGS 和 LDADD 等特殊变量<sup>译注4</sup>的前缀，可以将影响范围限定为该构建目标，而不波及所有构建目标。也可以使用 configure.ac 中 AC_SUBST 宏输出的变量， configure 脚本执行时会探测环境并在生成 Makefile 时对这些变量进行赋值<sup>译注5</sup>。此外，虽然构建目标相关的 CFLAGS 和 LDFLAGS 似乎有用，但在 Makefile.am 中增加编译选项会破坏可移植性，因为你无法预知编译器是否支持这些选项，或者是否确实需要（举例来说， LDFLAGS 中的 `-ldl` ，在 Linux 上是必需的，但在 FreeBSD 上是多余的），这些情况下，应该在 configure.ac 中加这些编译选项。

> 译注2: 该变量命名约定可参考 GNU Automake 手册 [3.3 The Uniform Naming Scheme][uniform] ，在 Alexandre Duret-Lutz 的 [Autotools 教程][autotools-tutorial]中称为 `where_PRIMARY` ，而且手册中也使用 PRIMARY 来指称 TYPEOFTARGET 。

> 译注3: 构建目标名作为前缀时需要进行[标准化处理][canonicalization]，除了英文句点外，还有更多字符需替换为下划线。

> 译注4: 这些变量在手册中被称为[用户变量][user-variables]，是构建人员专用的，开发人员不应该在 autotools 文件里对其赋值，但每个用户变量都对应有一个以 AM_ 为前缀的影子变量，开发人员可以使用这些影子变量。

> 译注5: 举例来说 `AC_SUBST([myhello], [myworld])` 定义了输出变量 myhello ， automake 会识别 AC_SUBST 宏，在生成 Makefile.in 时自动增加 `myhello = @myhello@` ，而其中的 `@myhello@` 模板变量会在 configure 脚本生成 Makefile 时展开为具体值，该赋值变成 myhello = myworld 。

configure.ac 中最常用的宏要数 AC_CHECK_HEADERS, AC_CHECK_FUNCS 和 AC_CHECK_LIB ，分别检测是否存在头文件、库函数和（带给定函数的）程序库。这些对于可移植性来说很重要，因为它们提供了一种方法来检测编译环境有哪些头文件（不操作系统中的系统头文件位置可能不同），检测某个系统库是否提供给定函数（如 OpenBSD 中没有 asprintf 函数，但是 GNU C 库和 FreeBSD 则有），并检测是否第三方库提供某些函数（例如在 GNU 系统中 libdl 库提供了 dlopen 函数，但 FreeBSD 系统中却由系统 C 库提供）。

除了检测编译环境是否有头文件和函数（或者程序库）之外，代码也需要作相应适配（如避免使用缺失的函数，或者提供一个自定义实现）。 Autoconf 通常和 autoheader 搭配使用，后者创建一个 config.h.in 模板，而 configure 脚本则根据该模板创建 config.h 头文件。 在 config.h 头文件中会定义一些形如 `HAVE_func` 和 `HAVE_header` 的预处理宏，C 和 C++ 代码中就可以使用条件编译 `#ifdef`/`#ifndef` 来判断编译环境特性，编译不同的实现代码。

下面是我总结的一些实践建议，对于创建高可移植性代码应该会有所帮助：

**config.h 头文件应被视为内部头文件**，只被该软件包内部使用。应避免编辑 config.h.in 模板增加额外代码，因为这会要求你手动与 configure.ac 的内容同步。

不幸的是在 Net-SNMP 等项目中和其他头文件一起导出了 config.h ，谁使用这些库就得包含这些头文件（或者复制一份 Net-SNMP 数据结构）。这很糟糕，因为使用 autotools 的库项目的目录结构应该是对外隐藏的（使用者可能根本不会采用 autotools ）。此外， autotools 行为也在演变中，相同的检测可能会产生不同的结果。如果编译环境中缺失某些特性，需要封装或者替换，那么这些自定义实现应放在内部头文件中而在安装时忽略（在 Makefile.am 中用 noinst_HEADERS 变量进行声明）。


**总是提供使用的 m4 宏库**。因为 autotools 已经被使用多年，许多可复用的软件包（如程序库）会安装其 m4 宏库于 `/usr/share/aclocal` 中，这样就可以使用其提供的宏函数来检测该软件包是否存在（例如使用 `-config` 等脚本）。 aclocal 会扫描这些文件提取宏定义，放入 aclocal.m4 中。开发者的工作环境中一般有这些宏库，但若该软件包并非必需的依赖，用户系统<sup>译注6</sup>可能就没有安装。通常这些都不是问题，因为用户几乎不用执行 aclocal ，但对 Gentoo 这种基于源码包的发行版，你可能需要对 Makefile.am 或者 configure.ac 打些补丁并重新执行 autoconf ，要是没有这些宏定义或者版本不兼容，那可就麻烦了。

> 译注6: 用户是指构建人员。通常开发人员负责上游代码仓库，不同的发行版有构建人员来负责打包加入该发行版的包管理系统。下文中的维护人员也是指构建人员。

为了规避这个问题，可以在软件包中创建一个 m4 子目录，放入所有用到的 m4 宏库。然后就可以使用 `aclocal -I m4` 来在系统宏库之前搜索该目录。这个目录可以加入版本控制，或者仅加入到发布包中。后者是最小需求，它减少了版本控制代码的量，而且自动采用最新的 m4 宏库版本，但代价是检出代码编译时可能无法进行 autoconf ，而只能从发布包中另行提取（未必可行，因为 configure.ac 可能加入了新的宏，或者项目新增了依赖）。另一方面，将 m4 目录加入版本控制，有时会诱使开发者修改这些宏定义。咋一看这似乎是合理的，毕竟这些 m4 已经在版本控制中，但软件包的维护人员会紧张，因为有时新版本的 m4 宏库会修复一些缺陷，增加新选项或修改安装路径，若 m4 宏库中的定义修改了，就无法直接替换为新版本了。这也意味着，当更新 m4 宏库时，需要重新打那些补丁。

m4 宏库总是很烦人的。不同的宏库之间通常有不少重复代码（得看 CFLAGS 和 LDFLAGS 的方式: 检测，或者采用 `-config` 脚本）。为了解决这个问题， GNOME 和 FreeDesktop 项目开发了一个叫做 [pkg-config][pkg-config] 的工具，它提供了一个可执行文件和一个 m4 宏库，支持检测给定程序库或者软件包是否存在，其依据是它们安装的 `.pc` 数据文件。这个方法简化了 configure.ac 的编写，也大大减少了 configure 脚本执行时间，因为它使用被检测包安装的 `.pc` 数据文件，而不是生成小程序进行链接测试。另一方面，这个方法也意味着，开发人员若写错了 `.pc` 文件，用户程序可就无法运行了，毕竟编译选项和链接选项都在 `.pc` 文件中给出了，configure 脚本不再检测该程序库本身。幸运的是，这种情况并不常见。

新办法是在 configure.ac 中使用 pkg.m4 宏库提供的 PKG_CHECK_MODULES 函数。该宏库应加入到 m4 目录中。由于 pkg-config 是必需的（因为 configure 脚本是通过该命令来解析 `.pc` 文件），那就无法保证开发人员和构建人员各自环境中的 pkg.m4 是相同的，也无法保证后者环境中的宏库没有缺陷，因为它可能是更老的版本呢。

**总是检测链接到哪些库**，若它是必需的。通常 autoconf 宏和 pkg-config 数据文件中定义了：若想链接本库，还需要链接到哪些库<sup>译注7</sup>。此外，有些函数，如上文提到的 dlopen 函数，在某些操作系统中由 libc 库提供，而在另一些操作系统中由其他库提供。这些情况下，需要检测使用函数时是否需要链接其他库，或者需要链接到特定的程序库，例如 libc 提供 dlopen 函数时，就不要链接到根本不存在的 libdl 程序库了，否则就会报错。

> 译注7: pkg-config 的 `--static` 选项会列出给定库依赖的其他库。

**谨慎使用 GNU 扩展**。高可移植性痛点之一就是使用扩展函数，也即哪些 GNU libc 提供但 BSD libc 和 uClibc  等 C 库不同的函数。当使用这些函数时，务必提供自定义实现，其性能和安全性可能稍差，但 libc 缺失该函数时可作为替代品。这些自定义实现需用 `#ifdef HAVE_func ... #endif` 条件编译，以便在已有实现时不产生重复定义。注意这些函数不应被导出，需在内部头文件中声明。

**避免编译不必要的 OS 相关代码**。当程序特定的库和操作系统时，可能整个的源代码文件都是平台相关的，这时可以在 configure.ac 中使用 [AM_CONDITIONAL][conditionals] 宏。这是个 automake 宏（仅使用 automake 构建项目时才有），支持在 Makefile.am 中使用 `if .. endif` 区块设置特殊变量。例如，声明一个 platformsrcs 变量并赋值为平台相关的源代码文件，然后在 _SOURCES 变量中引用该变量。

然而，使用 AM_CONDITIONAL 宏时有两个常见错误。第一个是在条件分支中使用 AM_CONDITIONAL （如在一个 if 或 case 分支中），这会导致 automake 报错（AM_CONDITIONAL 需在全局作用域中使用，在所有 if 语句块之外，所以需要先定义一个变量保存条件的状态，然后在使用 AM_CONDITIONAL 时检测该状态）。另一个问题是无法直接修改目标变量，需要先声明一个常规变量（条件不满足时其值为空）来增加或者删除源代码文件或者编译目标。

有许多项目为了避免编译特定代码路径，将整个文件中的代码都放在一个 `#ifdef ... #endif` 条件编译指令中。这种方式通常是可以工作的，但是代码因此而变得丑陋而且容易出错，因为很有可能漏掉了条件编译外的个别语句。而用户也容易被误导，因为表面上看来，有些源代码似乎在毫不相关的环境中也编译了。

**在检测操作系统或硬件架构时要有一些智能**。有时需要查找特定操作系统或硬件架构。正确的方式因在哪里需要而异。如果需要在 configure 中启用额外测试，或者需要在 Makefile 中增加额外目标，那就要在 configure.ac 中检测；另一方面，如果需要在源代码中进行差异化处理，例如使用汇编函数是编译器/预处理器直接相关的，那就要用 `#ifdef` 条件编译指令来测试平台相关的宏（如 `__linux__`, `__i386__`, `_ARC_PPC`, `__sparc__`, `_FreeBSD_` 和 `__APPLE__`）。

**不要在 configure.ac 中运行命令**。在 configure.ac 中检测硬件或操作系统时，应避免使用 uname 命令，即使这是最常见的测试方法之一。这是一个错误，因为它会破坏交叉编译。Autotools 支持在交叉编译时使用*主机定义*，即遵守 “硬件-厂商-操作系统”约定的字符串（实际上， GNU libc 是“硬件-厂商-操作系统-libc”的简称），例如 i686-pc-linux-gnu 和 x86_64-unknown-freebsd5.4 。CHOST 是指运行软件包的系统的主机定义，而 CBUILD 是编译机系统的主机定义；交叉编译则是指 CHOST 和 CBUILD 不同的情况。

在上例中，第一个主机定义是指 x86 架构和奔腾-2 或者更新的 CPU 上的使用 Linux 内核和 GNU libc 的操作系统（通常称为 GNU/Linux 系统）。第二个主机定义是指运行于 AMD64 上的 FreeBSD 5.4 操作系统。（对于使用 FreeBSD 内核以及 GNU libc 的 GNU/kFreeBSD 系统，主机定义会是“硬件-unknown-freebsd-gnu”，而对于使用 FreeBSD 内核及 libc 但采用 Gentoo 框架的 Gentoo/FreeBSD 系统，主机定义会是“硬件-gentoo-freebsd5.4”。）在 configure.ac 中使用 `$host` 和 `$build` 变量可以开启或者关闭平台相关特性。

**不要滥用“自动魔法”依赖** 。autotools 最有用的特性之一是能够自动检测程序库是否存在，从而自动启用额外功能。然而，滥用这个特性会给构建带来一些麻烦。这个特性对于初级用户来说非常有用。虽然大多数有复杂依赖关系的项目（例如多媒体工具 xine 和 VLC ）都会使用基于插件的架构来获得灵活性，但“自动魔法”给打包人员带来巨大麻烦，特别是在 Gentoo 这种基于源码包的发行版或者 FreeBSD ports 这种包管理框架上。当“自动魔法”项目构建时，那些编译环境中程序库支持的功能被自动启用。这意味着产生的二进制文件可能在另一个有相同的基础包但缺失某个特定可选包的系统上无法工作。此外，你无法辨别一个包的确切依赖关系，因为某些依赖并不是必需的，在程序库缺失时不会被编译。

为了解决这个问题， autoconf 支持向 configure 脚本增加 `--enable`/`--disable` 和 `--with`/`--without` 等选项。有了这些选项，就可以强制开启或者关闭某个选项（如对某个程序库或者某个特性的支持），而由自动检测完成缺省设置。

不幸的是，许多开发人员误解了用来创建选项的函数（[AC_ARG_ENABLE][package-options] 和 AC_ARG_WITH）的两个参数。他们提供了测试通过时和未通过时执行的动作。许多开发人员错误地认为，这两个参数定义了特性开启和关闭时执行的代码。当给传入参数以改变缺省行为时，这个办法通常是能工作的，但许多基于源码的发行版也会传入参数来确认缺省行为，这就导致了错误（强制启用的特性并不存在）。能够关闭可选特性来解除依赖关系（例如 Linux 上的 OSS 音频支持）对于用户而言总是件好事，他们不用编译肯定不会用的代码了，而对于包维护人员而言，也不必玩一些小把戏开启或关闭特性来满足用户需求了。

不同 autotools 版本之间的兼容性不够好，这给开发人员和维护人员都带来很大麻烦（因为它们安装相同的地方，使用相同的名字），但采用 autotools 免除了维护人员构建软件时的大量工作。以 Gentoo 的 ebuild 为例，那些没有采用 autotools 的项目往往是最复杂的，因为它们需要检测不同环境（有或者没有 NPTL ，在 Linux、 FreeBSD 或者 Mac OS X 上，使用 GNU libc 或者其他 libc ，等等），而这些工作 autotools 已可完全胜任。虽然为了修复上游代码仓库的 autotools 使用缺陷，包维护人员打了许多补丁，但这相对于使用一个移植性很差的构建系统而言是微不足道的。

Autotools 的学习曲线比较陡，不过随着在日常工作中的使用，相比手写 Makefile ，或者采用 imake 和 qmake 等诡异的构建工具，或者更糟糕地模拟 autotools 检测而言，还是会简单很多的。 Autotools 让移植到新的操作系统和硬件架构上的工作变得简单，节省了包维护人员和项目移植人员在新平台上尝试构建的时间。开发人员若能小心编写脚本，则甚至无需任何修改即可支持新平台。

[flameeyes]: http://blog.flameeyes.eu/
[autotools-tutorial]: https://www.lrde.epita.fr/~adl/autotools.html
[autobook-en]: https://www.sourceware.org/autobook/autobook/autobook_toc.html
[autobook-cn]: http://blog.csdn.net/chaolumon/article/details/3763413
[autotools-mythbuster]: http://autotools.io/
[autotools-best-practice-en]: http://archive09.linux.com/articles/114061
[autotools]: http://en.wikipedia.org/wiki/GNU_build_system
[cmake]: http://en.wikipedia.org/wiki/CMake
[scons]: http://www.scons.org/
[m4]: http://en.wikipedia.org/wiki/M4_(language)
[autotools-tutorial]: https://www.lrde.epita.fr/~adl/autotools.html
[uniform]: http://www.gnu.org/software/automake/manual/html_node/Uniform.html
[canonicalization]: http://www.gnu.org/software/automake/manual/html_node/Canonicalization.html
[user-variables]: http://www.gnu.org/software/automake/manual/html_node/User-Variables.html
[pkg-config]: http://www.freedesktop.org/wiki/Software/pkg-config/
[conditionals]: http://www.gnu.org/software/automake/manual/html_node/Usage-of-Conditionals.html
[package-options]: https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.69/html_node/Package-Options.html#Package-Options
