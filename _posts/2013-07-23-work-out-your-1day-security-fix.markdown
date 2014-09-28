---
layout: post
title: work out your 1day security fix
author: kc
tags:
- struts
- s2-016
- security
wordpress_id: 277
wordpress_url: http://106.186.30.221/blog/?p=277
date: 2013-07-23 15:22:44 +0800
---

Recently [struts][1] announced several highly critical vulnerabilities: [s2-015][2], [s2-016][3] and [s2-017][4], enabling malicious users to **execute any Java code** as [OGNL][5] expressions. The official advice is to upgrade to the newest version, namely 2.3.14.1 and 2.3.15.1. 

I believe many sites are using very old stable versions for the *poor sake of stability*, so it is highly possible that their admins feel hesitated to upgrade<!--more-->. I say it is poor because it is **good understanding rather than stick-to-one-version** that ensures stability, and my previous post *[Off by One Hour][6]* describes a victim of so called stability. 

Back to the topic, they might turn to blacklist OGNL expressions as described in [this post][7], which is possibly leaking and requires to rebuild OGNL library, or keep searching for other solutions leaving widened vulnerability window. That post also introduces a second solution by extending `DefaultActionMapper` and configuring struts to use that subclass, which does not require rebuilding of struts2-core and sounds better. 

Anyway, here I would like to introduce *a general way to apply security fix without much influence*, which is essentially a sense of **changes and versioning**. You might enjoy reading Scott Chacon's [Github flow][8] which is for in-house web development, and its companion [A successful Git branching model][9] which is traditional release flow that many software projects follow. You needn't to know much Java or struts at all, but I do assume you have some coding practice to do necessary adjustments acording to compiler complaints. 

The only trick is to compare the officially fixed release version to it's immediately ancestor to get the minimum change set, then you adjust that change set and reapply to your old base version. I prefer to name it *1day* fix, after the [0day][10] attack. For 0day fix, one has to invest a lot on the infrastructure, library, framework, etc, which is really a cost to bear, while for 1day fix, it is reasonable work. 

Notice the s2-016 announcement says the affected versions are up to 2.3.15 inclusively while the fixed version is 2.3.15.1, and the keyword for the security fix is *DefaultActionMapper*. So we go to the [official site][1] and find the [struts source archives][11]. We need the source code for those versions to examine the difference, as well as our old base version for later reapply. With source code ready, simply run "`diff -Nur struts-2.3.15 struts-2.3.15.1 > bigmass.patch`" to get the big mass of changes, against which we search *DefaultActionMapper* to get the source file named `src/core/src/main/java/org/apache/struts2/dispatcher/mapper/DefaultActionMapper.java` and a few changed lines that will help to reduce to the exact commit. Most changed lines in `DefaultActionMapper.java` help, while "`mapping.setName(cleanupActionName(name));`" caught my eyes. 

Notice that each new release introduces some features, bug fixes, and other improvments, each are commited as *logically separate changeset*, please refer to [here][12] for a sense of developer guidelines. So we are to find the exact commit that fixed the vulnerabilities. We have to retrieve struts source code repository to check the commit history, since release archives lack that information which are essentially certain *snapshots of the source code repository*. 

During the previous process figuring out archives, we might have also noticed [the build page][13], which tells us build instructions as well as to retrieve the repository by "`svn checkout http://svn.apache.org/repos/asf/struts/current`". Notice the `current` repository is parent repository for many subprojects namely struts, struts2, etc, and you know we are struts2 users. Also notice source file path in the struts2 is not exactly the one suggested previously, but `core/src/main/java/org/apache/struts2/dispatcher/mapper/DefaultActionMapper.java`, which is convention enforced by [maven][14] the build tool for most Java projects. Now let's check which revision and author is responsible to the selected line, "`mapping.setName(cleanupActionName(name))`", by "`svn blame core/src/main/java/org/apache/struts2/dispatcher/mapper/DefaultActionMapper.java`" in `struts2` directory, and we get "`1503127    rgielen                         mapping.setName(cleanupActionName(name));`". The blame output prefixes each source line with revision number and author, *1503127* and *rgielen* respecitvely in this case. 

Now it's time to find what the exact commit does by simply run "[svn log][15] \| less" in struts2 directory, then we search 1503127 and locate the commit message as: 

    ------------------------------------------------------------------------
    r1503127 | rgielen | 2013-07-15 16:02:23 +0800 (Mon, 15 Jul 2013) | 3 lines
    
    Merged from STRUTS_2_3_15_X
    WW-4140
    - Lukasz' patch applied [from revision 1502979]
    ------------------------------------------------------------------------
    r1503117 | lukaszlenart | 2013-07-15 14:40:25 +0800 (Mon, 15 Jul 2013) | 1 line
    
    Updates link to Plugin Registry

We can extract the [exact commit][struts-2.3.x-s2_015_016_017.patch] by [svn diff][svn_diff]:

    svn diff -r1503117:1503127 > struts-2.3.x-s2_015_016_017.patch

Comapring to the 3178-line big mass, the mininum change set is only 244 lines, which consists of 83 lines of functional code and 161 lines of tests. The assessment job for the security fix is very much reduced! 

However, be aware that the minimum changeset is against the revision 1503127, it *may or may not* apply to our old base version. We have to try the patch and resolve any conflicts. Let's first switch to the working release 2.6.35.1 to tell what the patch actually does. The patch is mostly against the constructor of class `DefaultActionMapper`, removing two `ParameterAction`'s and protecting against the left one, as [s2-016][3] explains. The protection depends on a `cleanupActionName()` helper method which is not in our old base version, so we have to copy that method and its dependencies into our security patch. After a few adjustments, we will be able to work out the security fix aginst our old base version. However, I won't show the final patch here, because it will leak my production configuration :-)

Now it's time to apply the final patch against our base version and rebuild our struts2.jar. We have already retrieved the source archive for our old release, haven't we? Expand the archive and apply the patch, by manually adjusting related lines, or "`patch -p0 < struts-2.3.x-s2_015_016_017.patch`" in `src` directory with conflict resolving. Then we try to rebuild the package with "[mvn clean package][rebuild]", as explained above, we are sure to meet many compilation errors, and each time we read the error source, understand the context and make proper adjustment. By the way, refer to [this post][16] to get around an inherent defect when building certain old versions. In addition, the following changes is advised to be applied to `core/pom.xml` to practice a better naming sense, where `2.x.y` refers to the old base version. 

    struts2-core
    +    2.x.y-s2_015_016_017
         jar
    -    Struts 2 Core
    +    Struts 2 Core fixed s2-015 s2-016 s2-017

Finally we get the security-patch-applied `struts2-core-x.y.z-s2_015_016_017.jar`, make another clean apply to verify the process, and replace into our production environment after QA test. Make sure the hack-prone version is removed. 

Software has bugs, sometime critical bugs, one has to keep an eye on the [annoucements][17] by subscribing to [mailing lists][18], and got a sense of the [history of releases][19]. Only a little concern is required to enjoy the value of softwares.

 [1]: http://struts.apache.org
 [2]: http://struts.apache.org/release/2.3.x/docs/s2-015.html
 [3]: http://struts.apache.org/release/2.3.x/docs/s2-016.html
 [4]: http://struts.apache.org/release/2.3.x/docs/s2-017.html
 [5]: http://commons.apache.org/ognl/
 [6]: /blog/2012/11/off-by-one-hour/
 [7]: http://chinahnzhou.iteye.com/blog/1909849
 [8]: http://scottchacon.com/2011/08/31/github-flow.html
 [9]: http://nvie.com/posts/a-successful-git-branching-model/
 [10]: http://en.wikipedia.org/wiki/Zero-day_attack
 [11]: http://archive.apache.org/dist/struts/source/
 [12]: http://git-scm.com/book/en/Distributed-Git-Contributing-to-a-Project#Commit-Guidelines
 [13]: http://struts.apache.org/dev/builds.html
 [14]: http://maven.apache.org
 [15]: http://svnbook.red-bean.com/en/1.7/svn.ref.svn.c.log.html
 [16]: http://grokbase.com/t/struts/user/08575t0wne/how-to-build-struts-2-0-11-1
 [17]: http://struts.apache.org/announce.html
 [18]: http://struts.apache.org/mail.html
 [19]: http://struts.apache.org/downloads.html
 [svn_diff]: http://svnbook.red-bean.com/en/1.7/svn.ref.svn.c.diff.html
 [struts-2.3.x-s2_015_016_017.patch]: {{ site.fileurl }}/2013/07/struts-2.3.x-s2_015_016_017.patch_.txt
 [rebuild]: http://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html
