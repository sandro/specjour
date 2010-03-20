# Specjour

_Distribute your spec suite amongst your LAN via Bonjour._

1. Start a dispatcher in your project directory.
2. Spin up a manager on each remote machine.
3. Say "goodbye" to your long coffee breaks.

## Requirements

* Bonjour or DNSSD (the capability and the gem)
* Rsync (system command used)
* Rspec (officially v1.3.0)

## Installation
    gem install specjour

## Start a manager
Running `specjour` on the command-line will start a manager which dispatches the tests to 1 worker by default

    $ specjour

## Setup the dispatcher
Edit the `Rakefile` in your project's directory

    require 'specjour' # unless it's already in your load path, i.e. config.gem 'specjour'
    require 'specjour/tasks/specjour'

## Distribute the tests
Run the rake task in your project directory to start the test suite.

    $ rake specjour

The worker reports passes/failures in batches of 25 so you won't get immediate feedback, override the batch size via `specjour --batch-size 1`

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
