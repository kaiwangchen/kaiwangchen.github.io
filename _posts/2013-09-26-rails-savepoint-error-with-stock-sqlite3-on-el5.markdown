---
layout: post
title: Rails SAVEPOINT error with stock SQLite on EL5
author: kc
wordpress_id: 371
wordpress_url: http://kaiwangchen.com/blog/?p=371
date: 2013-09-26 20:52:11 +0800
---

Well, I am running through the great [Rails tutorial][1], when suddenly bitten by [tests][2] from setion 6.2, User validations. I recall '`rails console --sandbox`' also triggers the error on saving. Looks like it is same to the [reported issue][3]. 

The problem is my CentOS 5 box ships with `sqlite-3.3.6-7`, while the `SAVEPOINT` feature is only supported with 3.6.8 and later. It is definitively a bug that Rails uses this feature on a non-supported version, and I feel hestitated to overwrite the OS package. 

The workaround in this post is to rebuild the sqlite3 gem to link with an up-to-date `libsqlite3.so`. For good knowledge of native extensions, I would recommend the official [RubyGems Guides][4] and Pat Shaughnessy's *[Don’t be terrified of building native extensions!][5]*.<!--more--> 

Interestingly, Rails-4.0 does detect the feature: 

    # activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb 
    # Returns true if SQLite version is '3.6.8' or greater, false otherwise.
    def supports_savepoints?
      sqlite_version &gt;= '3.6.8'
    end

Find below the error message. 

    $ bundle exec rspec spec/
    ......F..............
    
    Failures:

      1) User when email address is already taken 
         Failure/Error: user_with_same_email.save
         ActiveRecord::StatementInvalid:
           SQLite3::SQLException: near "SAVEPOINT": syntax error: SAVEPOINT active_record_1
         # ./spec/models/user_spec.rb:55:in `block (3 levels) in '
    
    Finished in 0.46675 seconds
    21 examples, 1 failure
    
    Failed examples:
    
    rspec ./spec/models/user_spec.rb:57 # User when email address is already taken 
    
    Randomized with seed 59295

Some guys as in github issue #5885 simply build an up-to-date sqlite without solving the problem. The trick is that the problem gem links to the stock sqlite library `/usr/lib64/libsqlite3.so.0` which is a symlink to `libsqlite3.so.0.8.6` in the same system directory. So system directory intruders have to replace the right file. 

    $ gem list -d sqlite3
    
    *** LOCAL GEMS ***
    
        sqlite3 (1.3.8)
        Authors: Jamis Buck, Luis Lavena, Aaron Patterson
        Homepage: http://github.com/luislavena/sqlite3-ruby
        License: MIT
        Installed at: /home/kc/.rvm/gems/ruby-2.0.0-p247@railstutorial_rails_4_0
    
        This module allows Ruby programs to interface with the SQLite3
        database engine (http://www.sqlite.org)
    
    $ ldd /home/kc/.rvm/gems/ruby-2.0.0-p247\@railstutorial_rails_4_0/gems/sqlite3-1.3.8/lib/sqlite3/sqlite3_native.so
        linux-vdso.so.1 =&gt;  (0x00007fffca9e6000)
        libruby.so.2.0 =&gt; /home/kc/.rvm/rubies/ruby-2.0.0-p247/lib/libruby.so.2.0 (0x00002b6de5891000)
        libsqlite3.so.0 =&gt; /usr/lib64/libsqlite3.so.0 (0x00002b6de5d1b000)
        libpthread.so.0 =&gt; /lib64/libpthread.so.0 (0x00002b6de5f76000)
        librt.so.1 =&gt; /lib64/librt.so.1 (0x00002b6de6191000)
        libdl.so.2 =&gt; /lib64/libdl.so.2 (0x00002b6de639b000)
        libcrypt.so.1 =&gt; /lib64/libcrypt.so.1 (0x00002b6de659f000)
        libm.so.6 =&gt; /lib64/libm.so.6 (0x00002b6de67d7000)
        libc.so.6 =&gt; /lib64/libc.so.6 (0x00002b6de6a5b000)
        /lib64/ld-linux-x86-64.so.2 (0x000000345fc00000)

To achive the workaround, firstly build an up-to-date sqlite3, 

    wget http://www.sqlite.org/2013/sqlite-autoconf-3080002.tar.gz
    tar zxf sqlite-autoconf-3080002.tar.gz
    cd sqlite-autoconf-3080002
    ./configure --prefix=/home/kc/sqlite3 && make && make install

Then, rebuild the gem, 

    gem uninstall sqlite3
    bundle config --local build.sqlite3 \
      --with-sqlite3-dir=/home/kc/sqlite3 \
      --with-sqlite3-lib=/home/kc/sqlite3/lib \
      --with-sqlite3-bin=/home/kcsqlite3/bin
    bundle install

The newly built gem is now linking to the up-to-date 3.8.0.2 version `/home/kc/sqlite3/lib/libsqlite3.so.0`, so the spec test is passed. Alert readers may notice the real library is also named `libsqlite3.so.0.8.6`, confusingly ;)

Notice with `--local` bundler saves the build instructions into `.bundle/config` from the project directory for later runs: 

    BUNDLE_BUILD__SQLITE3: --with-sqlite3-dir=/usr/local/sqlite3 --with-sqlite3-lib=/usr/local/sqlite3/lib
      --with-sqlite3-bin=/usr/local/sqlite3/bin

The *Build options* section of [bundler config reference][6] also points out an alternative way to build directly with gem command 

    gem install mysql -- --with...

Enjoy.

 [1]: http://ruby.railstutorial.org
 [2]: https://github.com/kaiwangchen/sample_app/commit/1d8e119d36b546a4802f22cf5e838c78101c0aca
 [3]: https://github.com/rails/rails/issues/5885
 [4]: http://guides.rubygems.org/
 [5]: http://patshaughnessy.net/2011/10/31/dont-be-terrified-of-building-native-extensions
 [6]: http://bundler.io/v1.3/bundle_config.html
