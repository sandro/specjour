History
=======

0.2.2
-----
*2010-04-22*

* [added] Backtrace for cucumber failures

0.2.1
-----
*2010-04-21*

* [added] The rsync daemon configuration file now lives in
  project_path/.specjour/rsyncd.conf. Edit your rsync exclusions there.
* [fixed] Don't report connection errors when CTRL-C is sent.

0.2.0
-----
*2010-04-20*

* [added] Cucumber support. `rake specjour:cucumber`
* [added] CPU Core detection, use -w to override with less or more workers
