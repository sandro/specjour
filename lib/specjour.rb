require 'uri'
require 'open3'
require 'drb'
require 'dnssd'
require 'forwardable'
require 'spec'
require 'spec/runner/formatter/base_text_formatter'

require 'specjour/marshalable_rspec_failure'

module Specjour
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :FinalReport, 'specjour/final_report'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :MarshalableFailureFormatter, 'specjour/marshalable_failure_formatter'

  autoload :Worker, 'specjour/worker'
  autoload :SpecReporter, 'specjour/spec_reporter'
  autoload :DistributedFormatter, 'specjour/distributed_formatter'
end
