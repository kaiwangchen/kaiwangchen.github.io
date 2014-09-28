---
layout: post
title: Poor Perl user's file sharing service
author:
tags:
- Perl
- Plack
- file sharing
wordpress_id: 47
wordpress_url: http://kaiwangchen.com/?p=47
date: 2012-10-01 01:50:25 +0800
---

I use Windows 7 as work station, CentOS 5 and 6 as production server, and MacBook Air at home, which differs from each other a lot. Sometimes I would like to browse and share certain directory, and then fell frustrated, because I simply can't remember the way to configure and to run service. As a command line user, I prefer to copy-paste and text editing. Once again, Perl makes life easy. 

Perl runs on [almost any environment][1], and is good candidate to provide consistent service. With [perlbrew][2], [cpanm][3] and [Plack][4], consistent file sharing could be easily achieved even in a fresh environment only with bash and C compiler. 

    $ curl -kL http://install.perlbrew.pl | bash
    $ perlbrew install perl-5.16.0
    $ perlbrew switch perl-5.16.0
    $ perlbrew install-cpanm
    $ cpanm Task::Plack

Of course these commands take some time to complete, then the service could be provided by 

    $ plackup -MPlack::App::Directory -e \
        'Plack::App::Directory->new(root => "$ENV{HOME}/repo/kaiwangchen.github.io")'

Or, if basic authentication is needed, 

    $ plackup -MPlack::Builder -MPlack::App::Directory -e '
    builder {
      enable "Auth::Basic", authenticator => sub {$_[1] eq "password"}; 
      Plack::App::Directory->new(root => "$ENV{HOME}/repo/kaiwangchen.github.io")
    }'

The shared directory could be accessed as 

    http://localhost:5000/

Interested in Plack? Here's a great [tutorial][5] by the author of Plack to start with.

 [1]: http://www.perl.org/about.html
 [2]: http://perlbrew.pl
 [3]: http://cpanmin.us
 [4]: http://plackperl.org
 [5]: https://github.com/miyagawa/plack-handbook
