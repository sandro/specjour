# Specjour

## FUCK SETI. Run specs with your spare CPU cycles.

1. Spin up a manager on each machine that can run your specs.
2. Start a dispatcher in your project directory.
3. Say farewell to your long coffee breaks.

## Installation
    gem install specjour

## Give it a try
Running `specjour` starts a dispatcher, a manager, and multiple workers - all
of the componenets necessary for distributing your test suite.

_(Read the Rails section first if your project uses Rails)_

    $ cd myproject
    $ specjour

## Start a manager
Running `specjour listen` will start a manager which advertises that it's ready
to run specs. By default, the manager runs tests for the project in the
current directory and uses your system cores to determine the number of workers
to start. If your system has two cores, two workers will run tests.

    $ specjour listen

## Distribute the tests
Dispatch the tests among the managers you started. Specjour checks the 'spec' and
'features' directories for tests.

    $ specjour

## Distribute a subset of tests
The first parameter to the specjour command is a test directory. It defalts to
the current directory and searches for 'spec' and 'features' paths therein.

    
    $ specjour spec # all rspec tests
    $ specjour spec/models # only model tests
    $ specjour features # only features
    $ specjour ~/my_other_project/features


## Rails
Each worker should run their specs in an isolated database. Modify the test database name in your `config/database.yml` to include the following environment variable (Influenced by [parallel\_tests](http://github.com/grosser/parallel_tests)):

    test:
      database: blog_test<%=ENV['TEST_ENV_NUMBER']%>

Running `specjour prepare` will set up the database for each worker.

### ActiveRecord Hooks
Specjour contains ActiveRecord hooks that clear database tables before running tests using `DELETE FROM <table_name>;`. Additionally, test databases will be created if they don't exist (i.e. `CREATE DATABASE blog_test8` for the 8th worker) and your schema will be loaded when the database is out of date.

## Custom Hooks
Specjour allows you to hook in to the test process on a per-machine and
per-worker level through the before\_fork and after\_fork configuration blocks.
If the default ActiveRecord hook doesn't set up the database properly for your
test suite, override it with a custom after\_fork hook.

    # .specjour/hooks.rb

    # Modify the way you use bundler
    Specjour::Configuration.before_fork = lambda do
      system('bundle install --without production')
    end

    # Modify your database setup
    Specjour::Configuration.after_fork = lambda do
      # custom database setup here
    end

A preparation hook is run when `specjour prepare` is invoked. This hook allows
you to run arbitrary code on all of the listening workers. By default, it drops
and recreates the ActiveRecord database on all workers.

    # .specjour/hooks.rb

    # Modify preparation
    Specjour::Configuration.prepare = lambda do
      # custom preparation code
    end

## Customize what gets rsync'd
The standard rsync configuration file may be too broad for your
project. If you find you're rsyncing gigs of extraneous data from your public
directory, add an exclusion to your projects rsyncd.conf file.

    $ vi workbeast/.specjour/rsyncd.conf

## Listen for multiple projects
By default, a manager will listen to the project in the current directory. If you want to listen for multiple projects, use the `--projects` flag.

    $ specjour listen --projects bizconf workbeast # run specs for the bizconf and workbeast projects

## Give your project an alias
By default, the dispatcher looks for managers matching the project's directory name. If you have multiple teams working on different branches of the same project you may want to isolate each specjour cluster. Give your project an alias and only listen for that alias.

    ~/bizconf $ specjour listen -p bizconf_08
    ~/bizconf $ specjour -a bizconf_08

    ~/bizconf $ specjour listen -p bizconf_09
    ~/bizconf $ specjour -a bizconf_09

## Working with git
Commit the .specjour directory but ignore the performance file. The performance
file constantly changes, there's no need to commit it. Specjour uses it in an
attempt to optimize the run order; ensuring each machine gets at least one
long-running test.

    $ cat .gitignore
    /.specjour/performance

## Compatibility

* RSpec 2
* Cucumber 0.9+
* Rails 2
* Rails 3

## Hacking on Specjour
If you want to hack on specjour, here is how to test your changes:

    source .dev
    rake # run the test suite sanely
    specjour # run the test suite with specjour
    cd sample
    specjour # run the cucumber test suite with specjour

Then if all is good, go to another app and test your changes on your test suite:

    gem build specjour.gemspec
    cd /path/to/your/project
    gem install -l /path/to/specjour/latest.gem
    specjour

## Thanks

* shayarnett - Cucumber support, pairing and other various patches
* voxdolo - Endless support, alpha testing, various patches
* l4rk and leshill - Removed Jeweler, added support for RSpec 2 and Cucumber 0.9+
* testjour - Ripped off your name
* parallel\_tests - Made my test suite twice as fast

## Note on Patches/Pull Requests

* Fork the project.
* `$ source .dev` to ensure you're using the local specjour binary, not the
  rubygems version
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Sandro Turriate. See MIT\_LICENSE for details.
