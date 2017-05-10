History
=======

2.0.0 (v2)
----------
* Specjour always starts a listener daemon unless one is already running. This means you're always sharing your cores by default.
* `specjour stop` stops the daemon running for the current project
* Your machine will share half available cores when running tests for a remote machine. This enables you to continue working while sharing your cpu.
* The listener can be run in the foreground with `specjour -f listen`.
* A constant number of workers can be set by the `-w` flag. Use this to set up a daemon on a machine devoted to specjour: `nohup specjour listen -w 4`
* Failing tests will be rerun after the suite completes. Disable with: `Specjour.configuration.rspec_rerun = false`
* The bonjour register/browse design has been flipped. Now, the listeners synchronously browse while the printer asynchronously advertises. This allows a listener to join the workers midway through a test run.
* You can run specjour on a single file, wherein all examples in the file will be distributed.
* Rspec and Rails are now treated as plugins. The plugins system is still a little rough, but should allow for adapting specjour to other testin frameworks like minitest and cucumber.
* Specjour uses its own formatter, instead of reusing an rspec formatter. The formatter is configurable which allows plugin authors to create the fomatter which best suits them.
* Specjour now launches a separate listener per project. This supports running specjour on two or more projects that have different Ruby versions.
* Removed the dependency on DRB.
* Removed the dependency on thor.
* Introduce a global specjour directory ($HOME/.specjour) to hold the lock file and daemon pids


0.7.1 / (master)
---------------------------
* [fixed] printer exit\_status returns false if there are no reporters
* [fixed] regression when running a subdirectory. Specjour was loading all
  specs, even those outside of the default spec directory, i.e. a fast\_specs/
  directory.
* [fixed] "file has vanished" bug. The specjour listener can now transition
  between networks without restarts.
* [fixed] before(:all). Specjour now distributes before(:all) as a group.
  Previously, each example would be distributed alone, effectively turning
  before(:all) into before(:each).

0.7.0 / 2012-11-21
---------------------------
* [added] Cucumber now distributes individual scenarios instead of files
* [fixed] Cucumber runs more than one feature (pierreozoux)
* [fixed] RSpec 2.12 compatible

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.6...v0.7.0)

0.6.6 / 2012-11-13
---------------------------
* [fixed] Not gathering all listeners (waits a full second for all replies)
* [fixed] Not killing all child processes

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.5...v0.6.6)

0.6.5 / 2012-10-17
---------------------------
* [fixed] RSpec 2.11 compatible
* [fixed] Undefined method errors when printer closes before clients disconnect

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.4...v0.6.5)

0.6.4 / 2012-09-17
---------------------------
* [added] RSpec formatter configurable via `Specjour::Configuration.rspec\_formatter`
* [changed] Always send KILL signal when terminating processes

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.3...v0.6.4)

0.6.3 / 2012-09-12
---------------------------
* [fixed] Observe filtered examples set in the RSpec configuration object

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.2...v0.6.3)

0.6.2 / 2012-08-20
---------------------------
* [fixed] File location for contexts within shared examples

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.1...v0.6.2)

0.6.1 / 2012-08-13
---------------------------
* [fixed] No longer prints tests that have yet to run when interrupting the
  process with CTRL-C
* [fixed] Use the correct file location for shared examples. As in, actually
  run them.

[Full Changelog](https://github.com/sandro/specjour/compare/v0.6.0...v0.6.1)

0.6.0 / 2012-07-19
---------------------------
* [fixed] First RSpec test to load would run twice
* [added] Rsync options are now customizable via `Specjour::Configuration.rsync\_options=`  
  Useful when running on machines that use a combination of vendored gems and gemsets, i.e.  
  `-aL --delete --ignore-errors --exclude=vendor/ruby --exclude=.bundle`
* [added] Benchmark times for various system status messages

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.6...v0.6.0)

0.5.6 / 2012-06-22
---------------------------
* [fixed] Specjour hang when attempting to resolve a bonjour reply
* [fixed] Specjour executes loader under current $LOAD\_PATH  
  Specjour no longer assumes the required gems are available globally. Useful when running specjour under a vendored environment (bundle install --path=vendor).

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.5...v0.5.6)

0.5.5 / 2012-05-31
---------------------------
* [fixed] Now compatible with thor 0.15.x

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.4...v0.5.5)

0.5.4 / 2012-05-29
---------------------------
* [fixed] Not running specs without 'spec/' argument

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.3...v0.5.4)

0.5.3 / 2012-04-12 - yanked
---------------------------
* [fixed] Writing to a nil socket; timeout too small (josephlord)
* [fixed] Eagerly loading Rspec (jgdavey)
* [fixed] Load path incorrectly matching specjour (jgdavey)

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.2...v0.5.3)

0.5.2 / 2012-02-21
---------------------------
* [fixed] Binary path used by Loader
* [fixed] Specjour prepare wouldn't wait for managers to complete
* [fixed] Slower machines adding completed tests back to suite

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.1...v0.5.2)

0.5.1 / 2012-02-21 - yanked
---------------------------
* [fixed] Dispatcher hanging after printing the report
* [added] More verbosity during startup

[Full Changelog](https://github.com/sandro/specjour/compare/v0.5.0...v0.5.1)

0.5.0 / 2012-02-20
----------------------

* [changed] Printer uses UNIX select instead of GServer (threads)
* [changed] Database is always dropped and reloaded using schema.rb or
  structure.sql
* [removed] RSpec < 2.8 compatibility
* [added] Memory utilizing forks. No longer forking and execing means workers
  start running tests faster.
* [added] Configuration.after\_load hook; runs after loading the environment
* [added] Configurable rsync port
* [added] Specs distributed by example, not file! Means better
  distribution/fast spec suites.
* [added] Rails compiled asset directory (tmp/cache) to the rsync inclusion
  list. Workers won't have to compile assets during integration tests.
* [fixed] SQL structure files can be used to build the database.
* [fixed] Long timeout while waiting for bonjour requests. The bonjour code has
  been rewritten.
* [fixed] Load specjour in its own environment when running bundle exec specjour
* [fixed] Forks running their parent's exit handlers.
* [fixed] Database creation when the app depends on a database upon environment
  load (something as simple as a scope would cause this dependency). As long as
  the regular test environment can be loaded, a worker without a database
  shouldn't raise an exception, instead the db should be created.

[Full Changelog](https://github.com/sandro/specjour/compare/v0.4.1...v0.5.0)

0.4.1 / 2011-06-17
------------------

l4rk and leshill

* [fixed] Cucumber failure reports not displayed


0.4.0 / 2011-03-09
------------------

l4rk and leshill

* [added] Remove Jeweler
* [added] Use RSpec2 for development
* [added] Cucumber 0.9+ compatibility
* [added] RSpec2 compatibility
* [removed] No longer supporting RSpec 1 and Cucumber 0.8

0.3.1 / 2010-10-16
------------------

#### Fixes
* Stopping bonjour actually stops the currently running service
* Only retry connecting to a DRb object 5 times instead of timing out
  trying to connect to one bad connection
* Set correct process name when the dispatcher starts a listener

## 0.3.0 / 2010-10-14

* [fixed] Cucumber output for scenario outlines (delitescere & supaspoida)
* [fixed] Undefined shared examples in Rspec2
* [fixed] INT signal sent to managers and workers, sets wants\_to\_quit where
  appropriate for Rspec2 and Cucumber
* [fixed] Error reporting for failed steps within a Background
* [added] Cucumber 0.9.x compatibility
* [added] RSpec 2.0.0 compatibility


## 0.3.0.rc8 / 2010-09-13

* [fixed] Custom hooks now load in Ruby 1.9.2
* [fixed] Specjour prepare correctly recreates the db
* [added] Support for loading test DB from SQL file
  (config.active\_record.schema\_format = :sql)
* [added] Rsync failures raise Specjour::Error

## 0.3.0.rc7 / 2010-09-09

* [fixed] Distributing absolute paths to remote machines.

* [added] Workers print the elapsed time of each test (redsquirrel)
* [added] Dispatcher loads specjour/hooks.rb, useful for monkey patching
  (redsquirrel)

* [changed] Decreased timeout to 2 seconds when searching for remote managers

## 0.3.0.rc6 / 2010-09-07

* [fixed] Ruby 1.9.2 support through minor changes and DNSSD upgrade
* [fixed] DbScrub.drop actually invokes the db:drop rake task
* [fixed] Prepare task ignores rspec's at\_exit callback, disabling the test
  suite from running after the prepare task completes.

## 0.3.0.rc5 / 2010-07-30

* [fixed] Shared example groups now supported in Rspec2

* [removed] Hyperthread detection removed as it proved too unstable while
  running selenium

## 0.3.0.rc4 / 2010-07-27

* [fixed] Only print cucumber summary when running features

## 0.3.0.rc3 / 2010-07-27

* [fixed] Cucumber prints elapsed time

* [added] Print hostname for each hostname (closes gh-8)

* [added] Rspec2 support


## 0.3.0.rc2 / 2010-07-14

* [fixed] Cucumber compatibility with 0.8.5

* [fixed] The before\_fork hook did not work in the rc1 because the custom hooks
  were loaded by the worker (after fork). We could have the manager preload the app
  but then you'll have stale managers. Instead, custom hooks are now located in
  the .specjour/hooks.rb file, essentially living outside of your application.

* [changed] The generated rsyncd.conf now syncs the .specjour directory
  allowing hooks to be loaded by managers and workers.

## 0.3.0.rc1 / 2010-07-12

* [removed] Rake tasks have been removed, use the command-line instead.

* [added] Thor is now used to parse command-line arguments. Try `specjour help`
  for more details.

* [added] Test discovery. Features will be autodiscovered by looking for a
  `features` directory in your project. If you only want to run features, use
  `specjour dispatch project_path/features`.

* [changed] No longer need to run a manager and a dispatcher in separate
  processes. When not distributing to other computers, simply run `specjour` in
  your project directory to run the suite among the number of cores on your
  machine.

* [added] Project aliases. If you want to isolate a few computers in the
  cluster, tell them to listen for a different project name and run the
  dispatcher with that new name.

        $ specjour listen --projects foo2
        $ specjour dispatch --alias foo2

* [added] Preparation. Running `specjour prepare` invokes the
  `Specjour::Configuration.prepare` block on each worker. By default this
  drops the worker's database and brings it back up.

* [removed] --batch option which sent back results in batches. Now that each
  spec is run one at a time, batching no longer makes sense.

* [removed] Global listening. You now must provide the project names you want to
  run specs for. Defaults to the project in your current working directory.

        $ specjour listen --projects foo bar

* [fixed] Rsync copies symbolic links. gh-6
* [fixed] DbScrub explicitly requires its dependencies and no longer loads the
  Rakefile. gh-10

## 0.2.5 / 2010-05-13

* [changed] The rails plugin now runs in a Rails.configuration.after\_initialize
  block

## 0.2.4 / 2010-05-10

* [added] Correct exit status
* [fixed] Will reconnect when connection is lost while requesting tests

## 0.2.3 / 2010-04-25

* [fixed] Absolute paths in rsyncd.conf restrict portability. The rsync daemon
  completely fails when it can't find the path to serve which typically happens
  running specjour on another computer. Remove your rsyncd.conf to regenerate a
  new one. Back it up first if you've made changes to it.
  **Backwards Incompatible**

* [fixed] CPU core detection works on OSX Core i7 (thanks Hashrocket!)

## 0.2.2 / 2010-04-22

* [added] Backtrace for cucumber failures

## 0.2.1 / 2010-04-21

* [added] The rsync daemon configuration file now lives in
  project\_path/.specjour/rsyncd.conf. Edit your rsync exclusions there.
* [fixed] Don't report connection errors when CTRL-C is sent.

## 0.2.0 / 2010-04-20

* [added] Cucumber support. `rake specjour:cucumber`
* [added] CPU Core detection, use -w to override with less or more workers
