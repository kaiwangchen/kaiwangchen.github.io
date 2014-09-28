---
layout: post
title: set up openvpn service for iPhone and Mac
author:
tags:
- openvpn
wordpress_id: 264
wordpress_url: http://106.186.30.221/blog/?p=264
date: 2013-07-22 02:20:55 +0800[
---

I feel sorry to live in a region with limited network access, even those great sites such as google, youtube and slideshare are blocked. That's why I got a VPS to tunnel. There are may VPN techniques, including PPTP, L2TP, and OpenVPN. I personally like OpenVPN best. I should admit that the other two are overly complicate for me to understand, and because CentOS 6.2 shipped with a defunct PPTP package (sorry, I miss the links), Debian become my choice again after years of ignorance. <!--more--> 

Since there are many wonderful tutorials on the web, I would prefer to list my references here instead of blindly coping instructions. I found these links very useful: 

The [debian OpenVPN wiki][1] is very encouraging by presenting from basic connection test to TLS setup. However, it is for server and your PC only, so no instructions for handset. As iPhone user I found [Remi's blog][2] very informative. For Mac desktop users, [Tunnelblick][3] should be the choice. 

I did experience a problem that Safari on my iphone was not accessing the web by the secure tunnel, however, suddenly it began to take it as default route. It is beyond my knowledge whether the `redirect-gateway` option make all things right or not. Anyway, it works! 

The other bad experience was that iTunes does not display the share folder box for apps in the first sight, instead one have to scroll down the pane to get it. However, the stupid UI does not display the scroll bar, making the false illusion that it is a one-page window. What a fuck.

 [1]: http://wiki.debian.org/OpenVPN "debian openvpn wiki"
 [2]: http://blog.remibergsma.com/2013/03/13/secure-browsing-on-ios-iphoneipad-using-openvpn-and-the-raspberry-pi/
 [3]: http://www.tunnelblick.net
