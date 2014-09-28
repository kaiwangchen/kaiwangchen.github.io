---
layout: post
title: FPM slowlog sucks
author:
tags:
- PHP
- FPM
- slowlog
wordpress_id: 104
wordpress_url: http://kaiwangchen.com/?p=104
date: 2012-10-05 04:39:49 +0800
---

Shipped with official [PHP][1] distribution, [FPM][2] (FastCGI Process Manager) is an alternative PHP FastCGI implementation with some additional features (mostly) useful for heavy-loaded sites, one of which is *slowlog* - logging scripts (not just their names, but their PHP backtraces too, using ptrace and similar things to read remote process' execute_data) that are executed unusually slow. 

However, does FPM slowlog always represent those scripts responsible to bad performance? Sadly that's a goal theoretcally impossible because of the way it works. Several months ago, I was badly misled by FPM slowlog entries, and actually the slowlog was almost useless with now and then corrupted dumps of script stack like <!--more-->this 

    [18-Aug-2012 17:39:43]  [pool www] pid 3202
    script_filename = /path/to/script.php
    [0x00000000013f1840] +++ dump failed

which corresponds to error log entries (entries are split into multiple lines to get better display, thus we have two entries in this case): 

    [18-Aug-2012 17:39:43] WARNING: [pool www] child 3202, 
      script '/path/to/script.php' (request: "GET /script.php") 
      executing too slow (4.511165 sec), logging
    [18-Aug-2012 17:39:43] ERROR: failed to ptrace(PEEKDATA) 
      pid 3202: Input/output error (5)

## The problem 

We got tons of *"upstream timed out (110: Connection timed out)"* in the local Nginx error log with following setup 

    Remote Nginx -- (cross IDC) 
                                \
                    (localnet)   \
     Local Nginx --------------  FPM

Apparently the FPM process pool is exausted, so Nginx has to wait until any FPM worker is available. FPM also has many entries in its error log and slowlog, leading a vast investication into all reported scripts, and the inevitable sad conclusion is possibly wrong direction. 

Notice the problem occurs only several times a week and we have cross-IDC deployment. I guess it might be some network issue. 

## Theory of FPM slowlogging

FPM slowlogging basically consists of these parts: 

1. Timing of script execution 
2. Expiration check 
3. Dumping of the PHP stack of the script 

You probably have heard about FPM manages pools of 

*worker* processes with a *master* process. When FPM server is started, it is only the master process, which does initialization like parsing php-fpm.conf and php.ini, loading PHP extension modules, and most notably open server sockets, one per pool, to be inherited by child processes, the workers. Then the master process `fork`s enough pools of workers, and enters into the *master event loop*, which besides other housekeeping tasks, periodly checks whether workers complete in time, and which dumps the stacktrace in the case of expiration. 

Each pool has a `scoreboard` structure holding the state of the pool itself and all workers belonging to it. The `scoreboard` is allocated as shared memory by `mmap(2)` with `MAP_SHARED` flag, and shared by all workers because they are always `fork`'ed from the master. Although the structure could be accessed by any of the workers, each of them usually updates its own share, and does not visit others', except for certain cases such as serving the `/status` special request when it peeks all `scoreboard`s to generate overall status report. 

The children of course bypass the master event loop, and then enter their independent *worker cycle*s, serving FastCGI requests one after another. A worker cycle basically consists of following steps 

    1. fpm_request_accepting       // FPM_REQUEST_ACCEPTING
    2. accept
    3. fpm_request_reading_headers // FPM_REQUEST_READING_HEADERS
    4. fcgi_read_request
    5. init_request_info
    6. fpm_request_info            // FPM_REQUEST_INFO
    7. php_request_startup
    8. fpm_request_executing       // FPM_REQUEST_EXECUTING
    9. php_execute_script
    10. fpm_request_end            // FPM_REQUEST_FINISHED
    11. php_request_shutdown

The functions with prefix `fpm_request_` are to update the `scoreboard` to reflect current processing stage and current time, while `fpm_request_reading_headers` additionally put down the accepted time. Other functions do heavy jobs and, since we focus on timing here, are not discussed. 

The master process fires up to check script execution time periodly, and the interval is calculated as `MIN(request_terminate_timeout, request_slowlog_timeout) * 1000 / 3`.

Every time the master searches for workers in `FPM_REQUEST_EXECUTING` stage, takes the difference between the *fireup time* and the recorded *accepted time* of the worker, and compares to the owner pool's [`request_slowlog_timeout`][3] to determine whether it is executing a slow script. If it is, then the master `ptrace(2)`es to the worker with `ATTACH` flag, and goes on searching. The worker stops to be traced, which in turn signals the master. Then the master calls `fpm_php_trace` to dump the stack of the script to the slowlog file, and then unattaches from the worker to let it continue. 

Since PHP interpreter's `executor_globals` structure is intialized by the master before `fork`ing, it is inherited by all workers. With known value of `executor_globals.current_execute_data`, the master is able to peek the stack of current script executed by the stopped worker. Slowlog is probably a unique feature that those general process managers are lacking by theory. 

## Native defect of FPM slowlogging

The `scoreboard`s are protected by locks when above functions with prefix `fpm_request_` are called, to provide exclusive access at one time. The slow execution checker copies with lock protection a worker's share of `scoreboard`, however, it releases the lock *immediately*, instead of having received *worker's acknowledge* of `ptrace` `ATTACH`. It simply is impossible to implement such strict synchronization with current architecture as of PHP 5.3.10, although the tracer can do some sanity check before dumping stack. As a result, the worker is free to go when the master is determining slow execution. When stopping to be traced, it *may* have completed that execution and is in any stage serving another request, so the tracer gets the chance of failure or worse, dumping out the stack of an irrelevant execution. 

Another defect is FPM slowlog by definition should consider the completion of receving FastCGI headers, instead of reading headres, as *start of script execution*, because reading FastCGI headers is a matter only after which can the worker choose a script to execute. It is not the script's fault to be caught in FastCGI parsing for a while.  

## The problem, revisited

Believe it or not, when the overhelming timeout occured, I found some connections, returned by `accept(2)`, got their first byte read after incredibly several seconds, while the scripts themselves executed very fast. They were considered slow because the long delay was added to slowlog timing, and since they finished fast, tracer got good chance to dump next execution. The problem was spotted by `strace`'ing all FPM processes and analyzing, with [accept_read.pl][4], the timing differences between `accept(2)` and related first `read(2)`. I guess it was the network stack's fault. 

I thought it was slow connections that exausted the worker pool, so a quick solution was switching to the following setup 

    Remote Nginx  
          |(http cross IDC)
          |         (localnet)
     Local Nginx --------------  FPM

That way, Nginx takes care of the delay, and FPM worker pool is protected. Keep in mind that in the quick setup, scripts may get false client addresses if designed without knowledge of HTTP proxy headers. Anyway, worked for me.

 [1]: http://php.net/downloads.php
 [2]: http://php.net/manual/en/install.fpm.php
 [3]: http://www.php.net/manual/en/install.fpm.configuration.php
 [4]: http://kaiwangchen.com/wp-content/uploads/2012/10/accept_read.pl_.txt
