History
=======

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


## 0.2.6 / master

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
