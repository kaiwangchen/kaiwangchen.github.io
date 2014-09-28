---
layout: post
title: tcpcopy 开发参考资料
author: kc
tags:
- tcpcopy
- pcap
- pfring
wordpress_id: 416
wordpress_url: http://kaiwangchen.com/blog/?p=416
date: 2014-02-10 16:41:15 +0800
---

最近 @wangbin579 在 QQ 群 192300573 里号召大家加入 tcpcopy 的重构计划，给出一些开发资料，非常不错，摘记如下： 

*   [The Linux Socket Filter: Sniffing Bytes over the Network][1]
*   [Inside the Linux Packet Filter][2]
*   [The BSD Packet Filter: A New Architecture for User-level Packet Capture][3]
*   [Flowreplay Design Notes][4]
*   [Monkey See, Monkey Do: A Tool for TCP Tracing and Replaying][5]
*   [10 Gbit Hardware Packet Filtering Using Commodity Network Adapters][6]
*   [tcpcopy 涉及的 RFCs][7]
*   [PF_RING User Guide][8]
*   [netmap: a novel framework for fast packet I/O][9]
*   [High Speed Network Traffic Analysis with Commodity Multi-core Systems][10]
*   [Programming with Libpcap: Sniffing the Network From Our Own Application][11]
*   [Improving the Performance of Passive Network Monitoring Applications with Memory Locality Enhancements][12]

 [1]: http://linuxjournal.com/article/4659
 [2]: http://linuxjournal.com/article/4852
 [3]: http://www.tcpdump.org/papers/bpf-usenix93.pdf
 [4]: http://tcpreplay.synfin.net/wiki/flowreplayDesign
 [5]: http://hoelzle.org/publications/usenix04monkey.pdf
 [6]: http://ripe61.ripe.net/presentations/138-Deri_RIPE_61.pdf
 [7]: https://github.com/wangbin579/tcpcopy/issues/138
 [8]: https://svn.ntop.org/svn/ntop/trunk/PF_RING/doc/UsersGuide.pdf
 [9]: https://www.usenix.org/system/files/conference/atc12/atc12-final186.pdf
 [10]: http://luca.ntop.org/imc2010.pdf
 [11]: http://undergraduate.csse.uwa.edu.au/units/CITS3231/reading/libpcap-programming.pdf
 [12]: http://www.ics.forth.gr/_publications/pcap-comcom.pdf
