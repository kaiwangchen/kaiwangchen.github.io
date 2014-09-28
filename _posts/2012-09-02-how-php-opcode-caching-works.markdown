---
layout: post
title: How opcode caching works with php-fpm
author: kc
tags:
- PHP
- caching
wordpress_id: 6
wordpress_url: http://kaiwangchen.com/?p=6
date: 2012-09-02 14:19:06 +0800
---

I have been wondering for days how PHP opcode caching works in my *php-fpm* setup. Several benchmark articles emerge by googling with keywords *php+opcode+caching*, yet the theory remains in the dark side. Finally I decided to dig into the source code of [APC-3.1.9][1] and [PHP-5.3.10][2], and here's my findings.

To answer two questions: 
1. How opcode caching is hooked in 
2. How opcode cache is shared across fpm worker processes 

The first question is explained well in [**TECHNOTES**][3] shipped with source code. Keep in mind that there are two kinds of caches: the *opcode cache*, a.k.a. *file cache* or *system cache*, and the *user controlled cache*, a.k.a. *user cache*. <!--more-->Both caches reside in the same memory segment under respective namespaces, and manipulated by different sets of cache updating functions, e.g. 

[`apc_compile_file`][4] for opcode cache, and [`apc_add`][5] for user cache. Caching support in frameworks like [CodeIgniter][6] is obviously related to *user cache*, and probably you prefer to [memcached][7], because APC cache can not be shared across hosts. 

The opcode cache is additionally updated automatically when PHP scripts are compiled that match [apc.filters][8] and that allowed by [apc.cache_by_default][9]. When APC module's intialization function, `apc_module_init`, is called, the standard PHP compiler previously registered to `zend_compile_file`, is replaced with the APC-provided wrapper, `my_compile_file`, which checks against *opcode cache* and, if necessary, compiles the script and updates the cache. So that's the hook point. Opcode caching takes effect transparently when APC is installed and enabled. 

    1815 int php_module_startup(sapi_module_struct *sf, zend_module_entry *additional_modules, uint num_additional_modules)
    1816 {
    
    // sets zend_compile_file to standard PHP compiler compile_file
    1888         zend_startup(&zuf, NULL TSRMLS_CC);
    
    // calls apc_module_init, sets zend_compile_file to my_compile_file
    2066         zend_startup_modules(TSRMLS_C);
    
    2141 }

The second question is related to memory allocator, also explained in **TECHNOTES**, and fpm process manager. In short, the cache memory segment is managed by an memory allocator as an offset-based link list, on which a hash table is built holding cached objects. That memory segment is usually `mmap`'ed, backed by POSIX shared memory objects, see `shm_open(3)`, or annoymous file on your filesystem, depending on the [apc.mmap_file_mask][10] configuration option. Backing stores are created and then immediately unlinked, as a result automatically reclaimed after all referencing processes has exited. There is no identifier or something for workers to look up the memory segment, no need of, because all worker processes are `fork`'ed from fpm master process, and that memory segment is `mmap`'ed before `fork`'ing thus inherited by all child processes. In case of your interest, PHP module initialization is at `php_cgi_startup`, which in turn calls `php_module_startup`, and fpm process manager later do `fork`s in `fpm_run`. 

**Edit 2012-09-03** This post is for php-fpm only, Apache httpd guys may refer to [FastCGI with a PHP APC Opcode Cache][11]

 [1]: http://www.php.net/manual/en/book.apc.php
 [2]: http://www.php.net/
 [3]: {{ site.fileurl }}/2012/08/TECHNOTES.txt
 [4]: http://www.php.net/manual/en/function.apc-compile-file.php
 [5]: http://www.php.net/manual/en/function.apc-add.php
 [6]: http://codeigniter.com/user_guide/libraries/caching.html#apc
 [7]: http://memcached.org/
 [8]: http://www.php.net/manual/en/apc.configuration.php#ini.apc.filters
 [9]: http://www.php.net/manual/en/apc.configuration.php#ini.apc.cache-by-default
 [10]: http://www.php.net/manual/en/apc.configuration.php#ini.apc.mmap-file-mask
 [11]: http://www.brandonturner.net/blog/2009/07/fastcgi_with_php_opcode_cache/
