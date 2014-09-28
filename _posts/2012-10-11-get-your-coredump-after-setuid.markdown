---
layout: post
title: Get your coredump after setuid(2)
tags:
- setuid
- coredump
author:
wordpress_id: 144
wordpress_url: http://kaiwangchen.com/?p=144
date: 2012-10-11 05:24:11 +0800
---

For the sake of security, services are usually running as distinct unpriviledged users, be they started by unpriviledged users or the super user, *root*. 

The problem with starting by an unpriviledged user is that it is sometimes unable to acquire certain resources, notably [priviledged ports][1] and huge number of [file descriptor][2]s for highly concurrent service. There are workarounds in most cases, for instance, port rediection eliminates the need of priviledged ports and system wide limits, see `pam_limits(8)`, could be tuned to grant the distinct user the ability to acquire more-than-usual resources, however, these solutions require additional administration work, *increasing maintenance burden and probably service instability*. 

Super power, if applied wisely, makes a better life for anybody. <!--more-->The administrator gets alleviated from the fate of trivality, the developer gets well paid for being sophisticated, and most importantly the employer profits from business supported by ready and sophisticated employees. Your usually have to pay to be wise, but not in the case of this post. 

Let's start the service with super power for it to acquire necessary resources, then it should change to run as some distinct unpriviledged user. A common program flow is 

    1) with super power, load protected configurations 
    2) open priviledged ports and protected files, if any 
    3) raise hard limits of the process according to application configuration 
    4) `fork`, with the parent and its children connected by `pipe`s and `signal`s 
    4.1) the parent stays in super power required for few housekeeping work 
    4.2) the children change to unpriviledged user, and enter businiess cycles

Notice real service is fulfiled by children as an unpriviledged user, with resources inherited from the super parent such as opened priviledged ports and protected files, and raised hard limit, see `setrlimit(2)`. The children as workers might be exploited, but it has non of [`capabilities(7)`][3] that are parcels of super power. The parent does only housekeeping work and accepts simple commands from children, so although it has full capabilities that are beloved of invaders, there is little chance for exploration. Principly safe it is. 

However, there's one problem that may have troubled many developers and that probably force them to turn to clumsy workarounds discussed previously. The ability to produce [coredump][4] is lost. The program crashes, but no stacktrace is available, making diagnosis a real headache. 

Please hold your rush for workarounds, calm down and read the right manual carefully, 

    prctl(2)
    
    PR_SET_DUMPABLE
         (Since  Linux 2.4) Set the state of the flag determining whether
         core dumps are produced for this process upon delivery of a sig-
         nal  whose  default  behaviour is to produce a core dump.  (Nor-
         mally this flag is set for a  process  by  default,  but  it  is
         cleared  when  a set-user-ID or set-group-ID program is executed
         and also by various system calls that  manipulate  process  UIDs
         and  GIDs).  In kernels up to and including 2.6.12, arg2 must be
         either 0 (process is not dumpable) or 1 (process  is  dumpable).
         Since  kernel 2.6.13, the value 2 is also permitted; this causes
         any binary which normally would not be dumped to be dumped read-
         able   by   root   only.    (See   also   the   description   of
         /proc/sys/fs/suid_dumpable in proc(5).)

It should be straightforwad that the missing of coredump is due to the fact that, when changing to run as unpriviledged user, the decisive 

*dumpable flag* is cleared by default. So the natural solution is having it set explicitly right after dropping super power, and because of being unpriviledged, the directory to save coredump files, usually the current directory of the process, should be writable by the effective user of the process. Hence the amendment,

    4.2) the children change to unpriviledged user, 
    switch on dumpable flag, and change to coredump directory,
    then enter businiess cycles

Another trival thing to note, you are not changing user by `seteuid(2)`, are you? Since effective user, which are checked against permissions, could be set to either real user or saved user, changing by `seteuid(2)` merely drops super power temperarily, and that power could be regained afterwards. Do a `setuid(2)` instead.

 [1]: http://en.wikipedia.org/wiki/TCP_and_UDP_port
 [2]: http://en.wikipedia.org/wiki/File_descriptor
 [3]: http://www.sevagas.com/IMG/pdf/exploiting_capabilities_the_dark_side.pdf
 [4]: http://en.wikipedia.org/wiki/Coredump
