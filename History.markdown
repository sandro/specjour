History
=======

0.2.3
-----
*2010-04-25*

* [fixed] Absolute paths in rsyncd.conf restrict portability. The rsync daemon
  completely fails when it can't find the path to serve which typically happens
  running specjour on another computer. Remove your rsyncd.conf to regenerate a
  new one. Back it up first if you've made changes to it.
  **Backwards Incompatible**

* [fixed] CPU core detection works on OSX Core i7 (thanks Hashrocket!)

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
