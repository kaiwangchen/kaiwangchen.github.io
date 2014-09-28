---
layout: post
title: Limit upload size with Nginx and backends
author: kc
tags:
- PHP
- Nginx
- upload
wordpress_id: 124
wordpress_url: http://kaiwangchen.com/?p=124
date: 2012-10-07 16:46:13 +0800
---

Once a time I was asked to set Nginx [`client_max_body_size`][1] to an unexpected high value, in addition to proper [`upload_max_filesize`][2] setting in `php.ini`, because if Nginx responds earily with *"413 Entity Too Large"*, the PHP backend won't get executed to return a [JSONP][3] response that resets client side state, resulting a *dead upload-in-progress state*. However, whatever `client_max_body_size` is set to, it *has a limit*, and for those oversized uploads, the dead states are there. That's probably not a good solution. <!--more-->

I am not good at [JQuery][4] work, anyway, the file upload workflow buried in [*dollar*][5]s is not AJAX at all, because AJAX file upload is simply [not supported][6]. Here's a well known *post-to-iframe* workaround, 

1. the user chooses a file to upload, 
2. that choice triggers some client-side script to submit the form. The magic is that, the form is [target][7]'ed at an *invisible iframe*, thus the current webpage, where the upload request is made, is not necessarily replaced by the response as in usual form submits; actually the response is displayed in the iframe, invisibly. 
3. at the same time, the client side enters the upload-in-progress state, possibly by showing a previously invisible busy-uploading image.
4. the client side sticks in that state, until any response is received that moves the client side to the next state, for examle, a successful response that moves the client side to the preview state by 

    <script>
      window.parent.upload_callback({"code":0,"pic":"20120723\/edd6518839b13f8f2aa7177202zAJLfccj.jpg"});
    </script>

or a rejected response that moves the client side to the error-then-reset state by 

    <script>
      window.parent.upload_callback({"code":-1,"message":"file is oversized"});
    </script>

 where `upload_callback` is the function to perform state transition, and gets called when the response is evaluated. For a quick demo, see [limit_upload_size.psgi][8]. 
So what the client side expects is a special response to perform state transition, and *whoever* responds is welcome, be it Nginx or PHP backend. So why not make the Nginx 413 error response to carry a specially crafted JSONP body indicating upload oversize? The solution could be expressed with following Nginx configuration snippet 

    client_max_body_size 2M; # your proper limit
    error_page   413 /error/413.html;

where the `413.html` is simply 

    <script>
    if (window.parent.upload_callback)
      window.parent.upload_callback({"code":-1,"message":"file is oversized"});
    </script>

Notice the `<script>` tag must be evaluated so the response shall have header `"Content-Type: text/html"` defined. In this way, the upload workflow is able to continue as expected, and with some additional performance gain, because no overhead is passed through to the backend. 

The following processing could be easily verified with `tcpdump` and `strace`: 

1. if request is larger than `client_max_body_size`, then Nginx responds, immediately after checking headers, with *"413 Entity Too Large"* whose content is per configuration. Notice it won't write any temporary file, whatever size it is. 
2. otherwise, Nginx should forward the request to a proper backend. And further, 
    1. if the request is larger than client_body_buffer_size, it will save to a temporary file and then forwards with that file, 
    2. otherwise, the reqeust is forwarded with all content carried in main memory. 

One thing to note is that although Nginx responds immediately with "*413 Entity Too Large*", it goes on to receive and discard all of file data, which kind of waste some network bandwidth.

 [1]: http://wiki.nginx.org/HttpCoreModule#client_max_body_size
 [2]: http://www.php.net/manual/en/ini.core.php#ini.upload-max-filesize
 [3]: http://en.wikipedia.org/wiki/JSONP
 [4]: http://api.jquery.com/
 [5]: http://api.jquery.com/jQuery/
 [6]: http://stackoverflow.com/questions/166221/how-can-i-upload-files-asynchronously-with-jquery
 [7]: http://www.w3.org/TR/html401/interact/forms.html
 [8]: http://kaiwangchen.com/wp-content/uploads/2012/10/limit_upload_size.psgi_.txt
