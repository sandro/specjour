require 'spec'
require 'spec/runner/formatter/base_text_formatter'
require 'specjour/protocol'
require 'specjour/core_ext/array'

autoload :URI, 'uri'
autoload :DRb, 'drb'
autoload :Forwardable, 'forwardable'
autoload :GServer, 'gserver'

module Specjour
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :DistributedFormatter, 'specjour/distributed_formatter'
  autoload :FinalReport, 'specjour/final_report'
  autoload :Manager, 'specjour/manager'
  autoload :MarshalableFailureFormatter, 'specjour/marshalable_failure_formatter'
  autoload :Printer, 'specjour/printer'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :Worker, 'specjour/worker'

  VERSION = "0.1.8".freeze
end
