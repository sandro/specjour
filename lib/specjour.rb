require 'spec'
require 'spec/runner/formatter/base_text_formatter'
autoload :URI, 'uri'
autoload :DRb, 'drb'
autoload :Forwardable, 'forwardable'

require 'benchmark'

# require 'specjour/spec_reporter'
require 'specjour/distributed_formatter'
require 'specjour/marshalable_rspec_failure'
require 'specjour/marshalable_failure_formatter'

module Specjour
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :FinalReport, 'specjour/final_report'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :Manager, 'specjour/manager'
  autoload :Worker, 'specjour/worker'

  TERMINATOR = "|ruojceps|"
end
