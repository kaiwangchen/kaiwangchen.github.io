---
layout: post
title: Java default timezone detection, revisited
author:
tags:
- Java
- timezone
- Linux
date: 2018-09-30 19:44:00 +0800
---

Yesterday some guy reminded me of the posts I wrote years ago about the Java default timezone detection problem on Linux system, [off-by-one-hour][1] and [explore-java-timezone][2].
He said they are of great help, and added that `/etc/timezone` might be involved in the detection process:

```
# java Test
2018-09-30 13:34:39, 720/GMT+08:00

# echo "Asia/Shanghai" > /etc/timezone

# java Test
2018-09-30 13:35:03 256/CST
```

The `/etc/timezone` file was not discussed in the old days. So this posts is to represent the implementation details instead of observation.

To recap the problem: Java tries to figure out the default timezone name from certain OS files if timezone is not explicitly set in system property or environment variable. It is confused if certain OS convention is broken.

The algorithm lies in Java native method `Timezone.getSystemTimeZoneID(javaHome)`, which is implemented in `java.base/share/native/libjava/TimeZone.c`.

The short description is:

1. Try reading the /etc/timezone
2. Next, try /etc/localtime to find the zone ID.
2.1 If it's a symlink, get the link name and its zone ID part.
2.2 If it's a regular file, find out the same zoneinfo file that has been copied as /etc/localtime.
3. If any above step catches, the correct timezone name is returned; otherwise, you get NULL.

So we can reason that Java timezone works if `/etc/timezone` is correct, or `/etc/localtime` is symlinked to or copied from proper zoneinfo file. Anyway, make sure the JRE shipped timezone data files are up to date.

The complete detail lies in the OS specific implementation from `java.base/unix/native/libjava/TimeZone_md.c`.

You can find the Java source code in the [openjdk source repository][3]. Here is a snippet for quick access, which is also a good example of comment:

```
/*
 * findJavaTZ_md() maps platform time zone ID to Java time zone ID
 * using <java_home>/lib/tzmappings. If the TZ value is not found, it
 * trys some libc implementation dependent mappings. If it still
 * can't map to a Java time zone ID, it falls back to the GMT+/-hh:mm
 * form.
 */
/*ARGSUSED1*/
char *
findJavaTZ_md(const char *java_home_dir)
{
    char *tz;
    char *javatz = NULL;
    char *freetz = NULL;

    tz = getenv("TZ");

    if (tz == NULL || *tz == '\0') {
        tz = getPlatformTimeZoneID();
        freetz = tz;
    }

    // snipped
}


#if defined(__linux__) || defined(MACOSX)

/*
 * Performs Linux specific mapping and returns a zone ID
 * if found. Otherwise, NULL is returned.
 */
static char *
getPlatformTimeZoneID()
{
    struct stat statbuf;
    char *tz = NULL;
    FILE *fp;
    int fd;
    char *buf;
    size_t size;
    int res;

#if defined(__linux__)
    /*
     * Try reading the /etc/timezone file for Debian distros. There's
     * no spec of the file format available. This parsing assumes that
     * there's one line of an Olson tzid followed by a '\n', no
     * leading or trailing spaces, no comments.
     */
    if ((fp = fopen(ETC_TIMEZONE_FILE, "r")) != NULL) {
        char line[256];

        if (fgets(line, sizeof(line), fp) != NULL) {
            char *p = strchr(line, '\n');
            if (p != NULL) {
                *p = '\0';
            }
            if (strlen(line) > 0) {
                tz = strdup(line);
            }
        }
        (void) fclose(fp);
        if (tz != NULL) {
            return tz;
        }
    }
#endif /* defined(__linux__) */

    /*
     * Next, try /etc/localtime to find the zone ID.
     */
    RESTARTABLE(lstat(DEFAULT_ZONEINFO_FILE, &statbuf), res);
    if (res == -1) {
        return NULL;
    }

    /*
     * If it's a symlink, get the link name and its zone ID part. (The
     * older versions of timeconfig created a symlink as described in
     * the Red Hat man page. It was changed in 1999 to create a copy
     * of a zoneinfo file. It's no longer possible to get the zone ID
     * from /etc/localtime.)
     */
    if (S_ISLNK(statbuf.st_mode)) {
        char linkbuf[PATH_MAX+1];
        int len;

        if ((len = readlink(DEFAULT_ZONEINFO_FILE, linkbuf, sizeof(linkbuf)-1)) == -1) {
            jio_fprintf(stderr, (const char *) "can't get a symlink of %s\n",
                        DEFAULT_ZONEINFO_FILE);
            return NULL;
        }
        linkbuf[len] = '\0';
        tz = getZoneName(linkbuf);
        if (tz != NULL) {
            tz = strdup(tz);
            return tz;
        }
    }

    /*
     * If it's a regular file, we need to find out the same zoneinfo file
     * that has been copied as /etc/localtime.
     * If initial symbolic link resolution failed, we should treat target
     * file as a regular file.
     */
    RESTARTABLE(open(DEFAULT_ZONEINFO_FILE, O_RDONLY), fd);
    if (fd == -1) {
        return NULL;
    }

    RESTARTABLE(fstat(fd, &statbuf), res);
    if (res == -1) {
        (void) close(fd);
        return NULL;
    }
    size = (size_t) statbuf.st_size;
    buf = (char *) malloc(size);
    if (buf == NULL) {
        (void) close(fd);
        return NULL;
    }

    RESTARTABLE(read(fd, buf, size), res);
    if (res != (ssize_t) size) {
        (void) close(fd);
        free((void *) buf);
        return NULL;
    }
    (void) close(fd);

    tz = findZoneinfoFile(buf, size, ZONEINFO_DIR);
    free((void *) buf);
    return tz;
}

#elif defined(__solaris__)
```

Good luck :-)

 [1]: {{ site.baseurl }}/2012/11/01/off-by-one-hour.html
 [2]: {{ site.baseurl }}/2012/11/03/explore-java-timezone.html
 [3]: http://hg.openjdk.java.net/jdk/jdk/archive/tip.zip
