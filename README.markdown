# Specjour

## FUCK SETI. Run specs with your spare CPU cycles.

_Distribute your spec suite amongst your LAN via Bonjour._

1. Spin up a manager on each machine that can run your specs.
2. Start a dispatcher in your project directory.
3. Say farewell to your long coffee breaks.

## Requirements
* Bonjour or DNSSD (the capability and the gem)
* Rsync (system command used)
* Rspec (officially v1.3.0)

## Installation
    gem install specjour

## Start a manager
Running `specjour` on the command-line will start a manager which advertises that it's ready to run specs. By default, the manager will use your system cores to determine the number of workers to use. Two cores equals two workers. If you only want to dedicate 1 core to running specs, use `$ specjour --workers 1`.

    $ specjour

## Setup the dispatcher
Require specjour's rake tasks in your project's `Rakefile`.

    require 'specjour/tasks/specjour'

## Distribute the specs
Run the rake task to distribute the specs among the managers you started.

    $ rake specjour

## Distribute the features
Run the rake task to distribute the features among the managers you started.

    $ rake specjour:cucumber

## Rails
Each worker should run their specs in an isolated database. Modify the test database name in your `config/database.yml` to include the following environment variable (Influenced by [parallel_tests](http://github.com/grosser/parallel_tests)):

    test:
      database: blog_test<%=ENV['TEST_ENV_NUMBER']%>

Add the specjour gem to your project:

    config.gem 'specjour'

Doing this enables a rails plugin wherein each worker will attempt to clear its database tables before running any specs via `DELETE FROM <table_name>;`. Additionally, test databases will be created if they don't exist (i.e. `CREATE DATABASE blog_test8` for the 8th worker) and your schema will be loaded when the database is out of date.

### Customizing database setup
If the plugin doesn't set up the database properly for your test suite, bypass it entirely. Remove specjour as a project gem and create your own initializer to setup the database. Specjour sets the environment variable PREPARE_DB when it runs your specs so you can look for that when setting up the database.

    # config/initializers/specjour.rb

    if ENV['PREPARE_DB']
      load 'Rakefile'
      
      # clear the db and load db/seeds.rb
      Rake::Task['db:reset'].invoke
    end

## Only listen to supported projects
By default, a manager will listen to all projects trying to distribute specs over the network. Sometimes you'll only want a manager to respond to one specific spec suite. You can accomplish this with the `--projects` flags.

    $ specjour --projects bizconf # only run specs for the bizconf project

You could also listen to multiple projects:

    $ specjour --projects bizconf,workbeast # only run specs for the bizconf and workbeast projects

## Customize what gets rsync'd
The standard rsync configuration file may be too broad for your
project. If you find you're rsyncing gigs of extraneous data from your public
directory, add an exclusion to your projects rsyncd.conf file.

    $ vi workbeast/.specjour/rsyncd.conf

## Use one machine
Distributed testing doesn't have to happen over multiple machines, just multiple processes. Specjour is an excellent candidiate for running 4 tests at once on one machine with 4 cores. Just run `$ specjour` in one window and `$ rake specjour` in another.

## Thanks

* shayarnett - Cucumber support, pairing and other various patches
* voxdolo - Endless support, alpha testing, various patches
* leshill - Made rsync daemon configurable
* testjour - Ripped off your name
* parallel_tests - Made my test suite twice as fast

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Sandro Turriate. See MIT_LICENSE for details.
