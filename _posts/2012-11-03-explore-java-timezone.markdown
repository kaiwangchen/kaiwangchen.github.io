---
layout: post
title: Expore java timezone
author:
tags:
- Java
- timezone
wordpress_id: 200
wordpress_url: http://kaiwangchen.com/?p=200
date: 2012-11-03 16:01:04 +0800
---

I previously wrote about the [off-by-one-hour][1] problem that obsolete timezone databases could cause false conversion to local time, and warned that certain programs might assume `/etc/localtime` being copied or symlinked from tzdata files in `/usr/share/zoneinfo`. This followup post demonstrates such an assumption and explores how Java applications decide their timezones, which was filed as a [bug][2] though. <!--more-->

Due to limited network access and too much old operating system, we applied a quick fix of by replacing obsolete only `/etc/localtime` with one from an up-to-date operating system. Then `date(1)` worked as expected, however, some guy reported that his Java program was logging in GMT time when restarted *across* the quick fix. Although it is a complex application, the defect could be reproduced by several lines of code. I would call this a good example of *precise and reliable reproduction* of defects, and the bad habbit of complaining in a complex context should be avoided completely. 

## The problem

Here is the source code reproducing the defect. 

    import java.util.Date;
    import java.text.DateFormat;
    import java.text.SimpleDateFormat;
    public class Test {
       public static void main(String args[]) {
          Date now = new Date();
          DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss, SSS/zzz");
          System.out.println(df.format(now));
       }
    }

It is able to produce correct localtime before quick fix even `date(1)` is not. After the quick fix is applied, `date(1)` output is OK, while the test program prints unexpected timezone. If both `/etc/localtime` and the one in `/usr/share/zoneinfo` are updated to correct version, both work with good output. 

    $ date
    Wed Oct 31 19:28:12 PST 2012
    $ java Test
    2012-10-31 20:14:28,329/PDT
    
    $ date
    Wed Oct 31 20:28:47 PDT 2012
    $ java Test
    2012-11-01 03:49:28,902/GMT
    
    $ date
    Wed Oct 31 20:29:44 PDT 2012
    $ java Test
    2012-10-31 20:47:29,601/PDT

## Discussion

Time to explore timezone in the Java world.

Although the preliminary impression was Java maintains its own timezone database regardless of the host operating system, it confused me a little why Java fell back to GMT. Let's stop guessing and dig into code.

TIPS: For quick source code access, visit links like [`java.util.Date`][3], otherwise, the source bundle could be retrieved from [official site][4]. 

Actually a `Date` object constructed with empty argument list simply captures epoch time with `System.currentTimeMillis()`, so that line of code is irrelavant. `SimpleDateFormat(pattern)` is a shortcut of `SimpleDateFormat(pattern, Locale.getDefault())`. `Locale.getDefault()` is singleton access to an object created with `Locale(language,country,variant)` which is simple encapsulation around string varriables, named `language`, `country` and `variant`, guessed out from system property `user.language`, `user.region`, `user.country` and `user.variant`. The default Locale essentially could be represented by something like `en_US`, and obviously is irrelavant. 

So the hard parts probably lie in the overloaded constructor 

    491    public SimpleDateFormat(String pattern, Locale locale)
    492    {
    493        if (pattern == null || locale == null) {
    494            throw new NullPointerException();
    495        }
    496
    497        initializeCalendar(locale);
    498        this.pattern = pattern;
    499        this.formatData = DateFormatSymbols.getInstance(locale);
    500        this.locale = locale;
    501        initialize(locale);
    502    }

The magic could be in line 497, 499 or 501. 

`DataFormatSymbols` is some mapping between numeric values and string representations, so line 499 is irrelavant. Let's take a look at line 497 which in turn calls `Calendar.getInstance(TimeZone.getDefault(), loc)`. Now you might get hit by strong feelings that `TimeZone.getDefault()` is the point, and create another small program to verify it. 

    public class Tz {
       public static void main(String args[]) {
          System.out.println(java.util.TimeZone.getDefault());
       }
    }

It actually `clone`s an object created by private method `setDefaultZone()`, which determines the `zoneID` by system property *`user.timezone`* or 

    547        // if the time zone ID is not set (yet), perform the
    548        // platform to Java time zone ID mapping.
    549        if (zoneID == null || zoneID.equals("")) { 
    550            String country = AccessController.doPrivileged(
    551                    new GetPropertyAction("user.country"));
    552            String javaHome = AccessController.doPrivileged(
    553                    new GetPropertyAction("java.home"));
    554            try {
    555                zoneID = getSystemTimeZoneID(javaHome, country);
    556                if (zoneID == null) {
    557                    zoneID = GMT_ID;
    558                }
    559            } catch (NullPointerException e) {
    560                zoneID = GMT_ID;
    561            }
    562        }
    563
    564        // Get the time zone for zoneID. But not fall back to
    565        // "GMT" here.
    566        tz = getTimeZone(zoneID, false);
    567
    568        if (tz == null) {
    569            // If the given zone ID is unknown in Java, try to
    570            // get the GMT-offset-based time zone ID,
    571            // a.k.a. custom time zone ID (e.g., "GMT-08:00").
    572            String gmtOffsetID = getSystemGMTOffsetID();
    573            if (gmtOffsetID != null) {
    574                zoneID = gmtOffsetID;
    575            }
    576            tz = getTimeZone(zoneID, true);
    577        }

Bad news is `getSystemTimeZoneID(javaHome, country)` is native, good news is the comments are full of hits. Anyway, we meet what was noticed earlier, that Java produces right local times with explicit *`-Duser.timezone=America/Los_Angeles`* argument. Additionally we can guess that the native method should fail to get a `zoneID` in the environment where `/etc/localtime` is not from `/usr/share/zoneinfo`, resulting the program fall back to GMT as the last resort. Let's trace the program to verify the point. 

    strace -o test.trace -f java Test 

One thing to note is that you should `strace(1)` with `-f` option to capture the Java program's complete interaction with the system. Try that command before quick fix, after quick fix, then after good practice. Examine the trace file, and you will have interesting findings that 

*   with alien `/etc/localtime`, Java searches through `/usr/share/zoneinfo` and gets no match. It fall back to take GMT as its timezone.
*   with `/etc/localtime` from `/usr/share/zoneinfo`, Java is able to determine its timezone from zone file name by either following the symlink, or traversing the directory to stat each tzdata file and stopping at the first match. It is irrelavant whether the content of the matched tzdata file is update or not.
*   with explicit timezone, no need to guess. 

After having determined the name of its timezone, a Java program looks up with the mapping between *system timezone* and *Java timezone*, `/usr/java/jdk1.6.0_30/jre/lib/zi/ZoneInfoMappings` and locates the timezone database file of the Java world such as `/usr/java/jdk1.6.0_30/jre/lib/zi/GMT` which is of different format from `tzfile(5)` though. Java then uses *its own* interpretation of timezones, and is independent on operating system tzdata files. 

## Conclusion

Reproduce bugs with simple code, and try to **reduce the context as much as possible**. When you reduce to its limit, you understand the problem. 

Update your operating system, at least essential parts.

 [1]: {{ site.baseurl }}/2012/11/01/off-by-one-hour.html
 [2]: http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=6626679
 [3]: http://javasourcecode.org/html/open-source/jdk/jdk-6u23/src-html/java/util/Date.html
 [4]: http://download.java.net/openjdk/jdk6/
