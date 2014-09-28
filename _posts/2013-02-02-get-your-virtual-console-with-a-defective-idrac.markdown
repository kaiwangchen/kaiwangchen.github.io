---
layout: post
title: Get your virtual console with a defective iDRAC
author: kc
wordpress_id: 211
wordpress_url: http://kaiwangchen.com/?p=211
date: 2013-02-02 22:29:51 +0800
---

Dell servers are notoriously defective, alas as a poor system adminstrator, I have to make a living with them. Fortunately, a hardworking mind is usually able to find out his workarounds. If you are frustrated trying to get the virtual console of a dead server with defective iDRAC, this post might be of help<!--more-->. For the novice, _Dell Remote Access Controller_, or DRAC for short, is a kind of Dell hardware to support out-of-band remote access to its servers, and virtual console is a feature provided by its Enterprise version which allows you to interact with the server as if you were sitting in front of it, the manual could be found [here][1]. 

The problem is, with Internet Explorer, you can not login to the iDRAC web interface any more, probably after quitting it without logout. Firefox helps a little further, however, you still can not get the virtual console to diagonise the dead operating system. Firefox reports aborted downloading of *viewer.jnlp* which is actually a startup description file interperted by *[Java Web Start][2] helper(javaws.exe)* to download the Java application from the web and to launch it. 

I experienced the problem with this version of iDRAC 

    Hardware Type: iDRAC6 	
    Hardware Version: 0.01 	
    Firmware Version: 1.70 (Build 21) 
    Firmware Update: Fri Apr 1 17:07:41 2011

and verified this version is OK: 

    Hardware Type: iDRAC6 	
    Hardware Version: 0.01 	
    Firmware Version: 1.80 (Build 17) 
    Firmware Update: Tue Nov 8 14:49:22 2011

The workaround is rather simple: capture the request and replay it with openssl to get the complete content of `viewer.jnlp`, save it to, say, vewer.jnlp and correct the title argument's encoding sequence, then double click the view.jnlp file and get the virtual console. 

One thing to note is that the viewer.jnlp is valid only once, if you try it twice, you get error prompt which falsely claims slow connection. In this case, you have to click the "Start Console" button and capture the request again. 

Since the request to get viewer.jnlp is via https secure channel, you may have trouble decrypt it with a general purpose network traffic capture tool like Wireshark, because the secret key of the server is required to decrypt SSL/TLS traffic. The Firebug addon is quite helpful in this case. Activate the network panel of Firebug before clicking the "Starte Console" button, you will find an entry for the request, then you can expand the entry and copy out its raw request, something like this, 

    GET /viewer.jnlp(@0@idrac-XXXXXXX%2C+PowerEdge+R610%2C+%u7528%u6237%uFF1Aroot@1359354221250) HTTP/1.1
    Host: <IDRAC_IP>
    User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:18.0) Gecko/20100101 Firefox/18.0
    Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    Accept-Language: zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3
    Accept-Encoding: gzip, deflate
    Referer: https://<IDRAC_IP>/sysSummaryData.html?cat=C00&tab=T00&id=P00
    Cookie: _appwebSessionId_=8f5ec0e255d7552abb915fde55cc25f5; batteriesIcon=status_normal; fansIcon=status_normal; intrusionIcon=status_normal; powerSuppliesIcon=status_normal; removableFlashMediaIcon=status_normal; temperaturesIcon=status_normal; voltagesIcon=status_normal
    Connection: keep-alive

Then paste the exact HTTP request after openssl having established the secure connection: 

    $ openssl s_client -connect &lt;iDRAC_IP&gt;:443

you get the view.jnlp file content in the HTTP response, and save it to view.jnlp on your desktop. Open it with your favorite text editor and replace the line 

     <argument>title=idrac-XXXXXXX%2C+PowerEdge+R610%2C+%u7528%u6237%uFF1Aroot</argument>

with 

     <argument>title=idrac-XXXXXXX%2C+PowerEdge+R610%2C+%3Aroot</argument>

Then you are good to go. 

Looks like the fault results from wrong encoding in that field. I guess the problematic substring `%u7528%u6237%uFF1A` is meant to represent Chinese translation of "User:" in UTF-16, Java's native encoding, while url-encoded UTF-8 characters are expected. Javascript function `decodeURIComponent()` is not able to deal with that case. 

Thank you for reading up to the end. As a reward, here is a solution to a companion problem that you get `"sec_error_reused_issuer_and_serial"` error when accessing the iDRAC web interface. Go certificate store and delete iDRAC default certificate. Cheers!

 [1]: http://support.dell.com/support/edocs/software/smdrac3/idrac/
 [2]: http://docs.oracle.com/javase/6/docs/technotes/guides/javaws/developersguide/contents.html
