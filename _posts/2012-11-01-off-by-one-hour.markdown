---
layout: post
title: Off by one hour?
author: kc
tags:
- day light saving
- timezone
wordpress_id: 174
wordpress_url: http://kaiwangchen.com/?p=174
date: 2012-11-01 15:59:46 +0800
---

Some people believe that stability is do-not-touch-anything, and they tend to keep one version for ever. The fact is that changes *fix problems* and implement new features, although probably introduce new defects. The real problem is that it demands knowledge to tell the context, and that it demands effort to acquire that knowledge. This post is an example of *the-true-evolve-into-false*. <!--more-->

Days ago I was asked to investigate an off-by-one-hour problem. I can't recall how many times I was involved to almost same problems, it looks like even those veterans don't understand what is local time. It is an unbelievable fact. 

## Discussion

A bare [`date(1)`][1] command prints your l*ocal time*, which essentially calls `gettimeofday(2)` then `localtime(3)`, which in turn depends on `/etc/localtime` to do the [epoch][2]-to-local conversion. 

This is the problem, it should be PDT instead: 

    $ date
    Wed Oct 31 19:28:12 PST 2012

For any time issues, one should firstly check the [UTC][3], a.k.a GMT, time against a known-correct clock such as [www.time.gov][4] 

    $ date --utc
    Thu Nov  1 03:29:44 UTC 2012

Usually that is a fix map from the [*system clock*][5] depending on your choice in the OS install process. It is universal, irrelative to where you are located, or precisely, the timezone settings of your system. You should not only have had the clock *correctly set*, but also have it *continously calibrated* which usually means that the Network Time Protocol daemon, a.k.a. ntpd, is running with good network connection or with special link to reference clocks. Typical computer clocks drift one second without calibration for days. 

Then check whether you are in the expected timezone. Depending on the `TZ` environment variable when `tzset(3)` is invoked, you may have an explicit timezone, a best approximation one, or UTC as the last resort. Best approximation is common case, when `/etc/localtime` is used, so make sure it links to the correct file or represents the right timezone data as expected. 

    $ ls -l /etc/localtime
    -rw-r--r--  1 root root 1017 Oct 31 20:28 /etc/localtime
    
    $ find /usr/share/zoneinfo/ -type f -exec md5sum {} \; \
         | grep `md5sum /etc/localtime | awk '//{print $1}'`
    ad7be76a1d7216104d9004a73e200efc  /usr/share/zoneinfo/America/Los_Angeles

Be warned that it is important to keep `/etc/localtime` a copy from or a symlink into the `/usr/share/zoneinfo` directory, otherwise you have good chance running into weird problems because *some programs assume that for unknown reason*. These [IANA time zone database][6] files are of format `tzfile(5)`, and consist of current timezone information such as leap seconds, day light saving settings, abbreviations, etc. You should be aware that certain local laws favor day light saving, and that people vote to change the law. So your timezone data file should be updated as soon as related local laws are changed, otherwise you would get wrong local time, notably off by one hour. 

The following timezone data file is out of date. 

    $ zdump /etc/localtime | grep 2012
    /etc/localtime  Sun Apr  1 09:59:59 2012 UTC = Sun Apr  1 01:59:59 2012 PST isdst=0 gmtoff=-28800
    /etc/localtime  Sun Apr  1 10:00:00 2012 UTC = Sun Apr  1 03:00:00 2012 PDT isdst=1 gmtoff=-25200
    /etc/localtime  Sun Oct 28 08:59:59 2012 UTC = Sun Oct 28 01:59:59 2012 PDT isdst=1 gmtoff=-25200
    /etc/localtime  Sun Oct 28 09:00:00 2012 UTC = Sun Oct 28 01:00:00 2012 PST isdst=0 gmtoff=-28800

The following timezone data file is up to date as of this post. 

    $ zdump /etc/localtime | grep 2012
    /etc/localtime  Sun Mar 11 09:59:59 2012 UTC = Sun Mar 11 01:59:59 2012 PST isdst=0 gmtoff=-28800
    /etc/localtime  Sun Mar 11 10:00:00 2012 UTC = Sun Mar 11 03:00:00 2012 PDT isdst=1 gmtoff=-25200
    /etc/localtime  Sun Nov  4 08:59:59 2012 UTC = Sun Nov  4 01:59:59 2012 PDT isdst=1 gmtoff=-25200
    /etc/localtime  Sun Nov  4 09:00:00 2012 UTC = Sun Nov  4 01:00:00 2012 PST isdst=0 gmtoff=-28800

Actually the US timezone problem was fixed around 2006, so if you are using an ancient monster like Fedora Core 2, you probably have the off-by-one-hour problem with `tzdata-2005f-1.fc2`. The discussion could be found [here][7]. 

An intuitive solution might be to replace `/etc/localtime` with a correct version of your time zone, however, you probably suffer from another problem that a restart of Java application afterwards could turn timestamps from correct localtime to GMT time. That deserves [another post][8], so for now just remember to update both /etc/localtime and corresponding timezone data files in the well known directory /usr/share/zoneinfo. 

Make /etc/localtime a symbol link into that directory is a good practice, although I would always recommend updating with vendor-provided package. 

## Checklist

Let's conclude the first post with these points: 1) system clock, 2) time zone name, and 3) tzdata files

 [1]: http://git.savannah.gnu.org/cgit/coreutils.git/tree/src/date.c
 [2]: http://en.wikipedia.org/wiki/Epoch_time
 [3]: http://en.wikipedia.org/wiki/Coordinated_Universal_Time
 [4]: http://www.time.gov/timezone.cgi?UTC/s/0/java
 [5]: http://en.wikipedia.org/wiki/System_time
 [6]: http://en.wikipedia.org/wiki/IANA_time_zone_database
 [7]: https://bugzilla.redhat.com/show_bug.cgi?id=173091
 [8]: {{ site.baseurl }}/2012/11/03/explore-java-timezone.html
