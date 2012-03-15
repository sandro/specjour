# Specjour

## FUCK SETI. Run specs with your spare CPU cycles.

## Instructions

1. Start a listener on every machine in the network. `# specjour listen`
2. Start a dispatcher. `# specjour`
3. Say farewell to your long coffee breaks.

## Installation
    gem install specjour

### Rails
Each worker needs an isolated database. Modify the test database name in your
`config/database.yml` to include the following environment variable (Influenced
by [parallel\_tests](http://github.com/grosser/parallel_tests)):

    test:
      database: project_name_test<%=ENV['TEST_ENV_NUMBER']%>

## Give it a try
Run `specjour` to start a dispatcher, manager, and multiple workers in the same
terminal window.

    $ cd myproject
    $ specjour

## Start a manager
If you wish to share your computing power with the rest of the computers in your network, run `specjour listen` to start a long running process. The next time you, or any of your co-workers run `specjour`, they'll find your machine.

    $ specjour listen

## Distribute the tests
Dispatch the tests among the managers in the network. Specjour checks the
'spec' and 'features' directories for tests to send to the listening
managers.

    $ specjour

## Supplementary

### Distribute a subset of tests
The first parameter of the specjour command is a test directory. It defalts to
the current directory and searches for 'spec' and 'features' paths therein.

    $ specjour spec # all rspec tests
    $ specjour spec/models # only model tests
    $ specjour features # all features

### Custom Hooks
Specjour allows you to hook in to the test process on a per-machine and
per-worker level through the before\_fork and after\_fork configuration blocks.
If the default hooks don't work for your project, they can be overridden.

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
you to run arbitrary code on all of the listening workers. By default, it
recreates the database on all workers.

    # .specjour/hooks.rb

    # Modify preparation
    Specjour::Configuration.prepare = lambda do
      # custom preparation code
    end

### Customize what gets rsync'd
The standard rsync configuration file may be too broad for your
project. If you find you're rsyncing gigs of extraneous data from your public
directory, add an exclusion to your project's rsyncd.conf file.

    $ vi workbeast/.specjour/rsyncd.conf

### Listen for multiple projects
By default, a manager will listen to the project in the current directory. If you want to run tests for multiple projects, use the `--projects` flag.

    $ specjour listen --projects bizconf workbeast # run tests for the bizconf and workbeast projects

### Give your project an alias
By default, the dispatcher looks for managers matching the project's directory name. If you have multiple teams working on different branches of the same project you may want to isolate each specjour cluster. Give your project an alias and only listen for that alias.

    ~/bizconf $ specjour listen --projects bizconf_08
    ~/bizconf $ specjour --alias bizconf_08

    ~/bizconf $ specjour listen --projects bizconf_09
    ~/bizconf $ specjour --alias bizconf_09

### Working with git
Commit the .specjour directory but ignore the performance file. The performance
file constantly changes, there's no need to commit it. Specjour uses it in an
attempt to optimize the run order; ensuring each machine gets at least one
long-running test.

    $ cat .gitignore
    /.specjour/performance

## Compatibility

* RSpec 2
* Cucumber 0.9+
* Rails 3

## Hacking on Specjour
If you want to hack on specjour, here is how to test your changes:

    source .dev
    rake # run the test suite sanely
    specjour # run the test suite with specjour

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
* parallel\_tests - Inspiration

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
