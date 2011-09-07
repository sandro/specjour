History
=======

0.5.0 / (not released)
----------------------

* [changed] Printer uses UNIX select instead of GServer (threads)
* [removed] RSpec < 2.5 compatibility
* [added] Memory utilizing forks. No longer forking and execing means workers
  start running tests faster.
* [added] Configuration.after_load hook run after loading the environment
* [fixed] Database creation when the app depends on a database upon environment
  load (something as simple as a scope would cause this dependency). As long as
  the regular test environment can be loaded, missing a database in a worker
  environment shouldn't raise an exception, instead the db should be created.

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
