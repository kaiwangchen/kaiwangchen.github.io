---
layout: post
title: Optimize MySQL binlog size with batch update
author: kc
tags:
- MySQL
- Perl
wordpress_id: 32
wordpress_url: http://kaiwangchen.com/?p=32
date: 2012-09-23 16:27:22 +0800
---

Recently we spotted a dramatic drop of daily binlog size from about 12GB to below 3GB. This post analyzes the cause and discusses batch update optimization for busy tasks with small payload. <!--more-->

## The problem

The MySQL node related is the store of our log analysis system, updated every few minutes when the access log is rotated. The interval's data is broken down by plenty of counters, and the store was updated once per counter by this SQL statement 

    INSERT INTO $new_table (counter, day_accum, week_accum, month_accum, total_accum)
    VALUES (?,?,?,?,?,?)
    ON DUPLICATE KEY UPDATE
        day_accum=VALUES(day_accum), week_accum=VALUES(week_accum), month_accum=VALUES(month_accum), total_accum=VALUES(total_accum)

Then one day I made some changes to meet business needs, and incidentally replaced the one-query-per-counter mechanism with batch update, about 

*3,000* counters per batch. The batch update is implmented by supplying more placeholders for additional rows: 

    INSERT INTO $new_table (counter, day_accum, week_accum, month_accum, total_accum)
    VALUES (?,?,?,?,?,?),(?,?,?,?,?,?), ...
    ON DUPLICATE KEY UPDATE
        day_accum=VALUES(day_accum), week_accum=VALUES(week_accum), month_accum=VALUES(month_accum), total_accum=VALUES(total_accum)

I also wrote a helper subroutine to ease the assemble of this SQL, and here's [sql_n example usage][1]. 

Perhaps applying multiple changes of different purpose per source code commit is not recommended practice, but that discussion is beyond this post. Anyway, we got the happy accident. 

## The math

Now allow me show some calcuations. 

With our schema, each field is of MySQL `int` type, that is, one row's data is roughly about `4 bytes per field x 6 fields = 24 bytes`. With one-query-per-counter mechanism, the effective size is estimated as the length of SQL statement text plus data size above. With $new_table sized about 28 bytes, the overall size is roughly `261 for SQL text without placeholder + 13 for placeholders + 24 for row data = 298 bytes`. 

Notice the payload occupies only *24 / 298 = 8%* of effective size. 

    $ cat < INSERT INTO 1234567890123456789012345678 (counter, day_accum, week_accum, month_accum, total_accum)
    VALUES 
    ON DUPLICATE KEY UPDATE
        day_accum=VALUES(day_accum), week_accum=VALUES(week_accum), month_accum=VALUES(month_accum), total_accum=VALUES(total_accum)
    EOF
    261

With batch update, the SQL text without placeholder is identical to that of one-query-per-counter mechanism, however, that text is shared by the whole batch, so the effective size for submitting one counter is `261 / 3000 as batch size + 13 for placeholders + 1 for comma + 24 bytes of row data = 39 bytes`. The estimated drop ratio would be *7.5:1* excluding saved housekeeping bytes, saving a good amount of disk space with hundreds of millions of counter updates per week. In our case, that is more than 50GB of waste on a shared database server with limited disks. 

## Discussion

MySQL might not be the best store for statistics counters, however, there are some reasons for sticking to it:

1. people know SQL, know MySQL, and
2. migration is lots of work, we have limited time, and most importantly
3. MySQL is usually not the *root cause* of performance suck. 

MySQL batch update has the pros of reducing lock contentions of query cache, eliminating round trips between client and server, and dramatic reduction of binglog size. It has the cons of longer table locks, and potential partial update with non-transational storage engine. It is also a MySQL specific feature, and subjects to portablity issues. However, it fits well into *native* batch tasks. 

Perl DBI provides [`execute_array`][2] method to execute the prepared statement once for each parameter tuple, and it looks like that `execute_array` executes one row of data after another, and that it is more a programming convenience than a database level optimization. 

## Conclusion

Busy updates with small payload are good candidates for optimizations notably batch update.

 [1]: http://kaiwangchen.com/wp-content/uploads/2012/09/batch_update_example.pl_.txt
 [2]: http://search.cpan.org/~timb/DBI/DBI.pm#execute_array "perldoc DBI"
