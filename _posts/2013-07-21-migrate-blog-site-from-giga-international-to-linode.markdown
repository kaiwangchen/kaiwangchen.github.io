---
layout: post
title: Migrate blog site from giga-international to linode
author: kc
tags:
- wordpress
wordpress_id: 250
wordpress_url: http://106.186.30.221/blog/?p=250
date: 2013-07-21 21:47:00 +0800
---

Alas, I finally decided to perform the migration today. I feel a little sad that the linode network I picked, Tokyo, is not as fast as I expect, the round-trip time is still 200ms from my ISP, comparing to about 300ms with giga-international. You know, [giga][1]'s 9.99 EUR per month configuration provides 4GB ram, 200GB disk and unlimited transfer, much better than [linode][2]'s 20 USD per month configuration of 1GB ram, 24GB disk and 2GB monthly transfer. I am trying to tell myself that I will never use up to linode-provided capacity.<!--more-->

The migration was not easy job, since the domain name is not updated to point to my linode VPS yet: wordpress have `siteurl` and `home` configured in the database, so every request goes to giga when the linode instance runs with data imported from giga. I had a hard time before noticing the following trick: 

    update wp_options set 
      option_value = 'http://106.186.30.221/blog' where option_name in( 'siteurl', 'home');

I should have been aware of the hosts file on my test box... it's a shame really. 

The new instance is now wordpress-3.5.2 instead of old 3.4.1. Wordpress does good job detecting and migrating database even with fresh install of latest code. The process is kept for the sake of later reference, the operating system here is Debian 7: 

    apt-get update
    apt-get upgrade
    apt-get install apache2-mpm-perfork mysql-server php5 php5-mysql
    wget http://wordpress.org/latest.tar.gz
    tar zxf latest.tar.gz
    mv wordpress /var/www/blog
    ln -s ../mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load

Edit `/etc/apache2/sites-enabled/000-default` to configure `AllowOverride FileInfo` for `/var/www/` section, which is to enable [wordpress permalink][3]. Although `.htaccess` could be generated if wordpress instance have right to write the file, its content is listed here to get an intuitive impression. 

    RewriteEngine On
    RewriteBase /blog/
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /blog/index.php [L]

At this point, a fresh wordpress instance is almost ready, except the database connection configuration in `wp-config.php`, good news is Wordpress ships `wp-config-sample.php` as a sample file, simply make a copy and edit database section is enough. Since it's a migration instead a [fresh install][4], the next steps are to copy data from the old instance: Stop the instance and dump the wordpress database to `kcblog.sql`, copy to the new VPS, then 

    mysql -e 'create database kcblog'
    mysql kcblog < kcblog.sql
    mysql kcblog -e "update wp_options set option_value = 'http://106.186.30.221/blog' where option_name in('siteurl', 'home')"
    scp -r giga-vps:/wp-content/uploads /var/www/blog/wp-content/

Ensure the filesystem permissions with `chown -R www-data:www-data /var/www/blog`, note the above owner is from /etc/apaches/envvars, namely `APACHE_RUN_USER` and `APACHE_RUN_GROUP`. 

Finally make the giga VPS redirects to the linode VPS by `rewrite ^ http://106.186.30.221/blog redirect;`. I prefer redirect here because the round-trip time between the two VPS is a bit slow, about 200ms, and in the meanwhile updates DNS records. 

PS. I usually tend to have process owner differ from code owner to defend against vulnerabilities that enable intruder's to change application code, however, looks like many features are disabled such as easy upgrade of wordpress and easy configuration of permlinks, I would trade security for convenience for this personal site.

 [1]: http://contabo.com/?show=vps
 [2]: https://www.linode.com/
 [3]: http://codex.wordpress.org/Using_Permalinks "permalinks"
 [4]: http://codex.wordpress.org/Installing_WordPress
