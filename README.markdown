# Specjour
_Distribute your spec suite amongst your LAN via Bonjour._

1. Start a dispatcher in your project directory.
2. Spin up a manager on each remote machine.
3. Say farewell to your long coffee breaks.

## Requirements
* Bonjour or DNSSD (the capability and the gem)
* Rsync (system command used)
* Rspec (officially v1.3.0)

## Installation
    gem install specjour

## Start a manager
Running `specjour` on the command-line will start a manager which advertises that it's ready to run tests. By default, the manager will only use one worker to run the tests. If you had 4 cores however, you could use `specjour --workers 4` to run 4 sets of tests at once.

    $ specjour

## Setup the dispatcher
Require specjour's rake tasks in your project's `Rakefile`.

    require 'specjour/tasks/specjour'

## Distribute the tests
Run the rake task to distribute the tests among the managers you started.

    $ rake specjour

## Rails
Edit your config/environment.rb

    config.gem 'specjour'

Each worker should run their specs in an isolated database. Modify the test database name in your `config/database.yml` to include the following environment variable (Influenced by [parallel_tests](http://github.com/grosser/parallel_tests)):

    test:
      database: blog_test<%=ENV['TEST_ENV_NUMBER']%>

Each worker will attempt to clear its database tables before running any specs via `DELETE FROM <table_name>;`. Additionally, test databases will be created if they don't exist (i.e. blog_test8 for the 8th worker) and will be migrated when necessary.

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
