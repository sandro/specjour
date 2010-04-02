autoload :URI, 'uri'
autoload :DRb, 'drb'
autoload :Forwardable, 'forwardable'
autoload :GServer, 'gserver'
autoload :Timeout, 'timeout'
autoload :Benchmark, 'benchmark'
autoload :Logger, 'logger'
autoload :Socket, 'socket'

module Specjour
  autoload :Connection, 'specjour/connection'
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :Manager, 'specjour/manager'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelpers, 'specjour/socket_helpers'
  autoload :Worker, 'specjour/worker'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'

  module Rspec
    require 'spec'
    require 'spec/runner/formatter/base_text_formatter'

    autoload :DistributedFormatter, 'specjour/rspec/distributed_formatter'
    autoload :FinalReport, 'specjour/rspec/final_report'
    autoload :MarshalableFailureFormatter, 'specjour/rspec/marshalable_failure_formatter'
  end

  module Cucumber
    require 'cucumber'
    autoload :DistributedFormatter, 'specjour/cucumber/distributed_formatter'
  end

  VERSION = "0.1.18".freeze

  class Error < StandardError; end

  def self.logger
    @logger ||= new_logger
  end

  def self.new_logger(level = Logger::UNKNOWN)
    @logger = Logger.new $stdout
    @logger.level = level
    @logger
  end

  def self.log?
    logger.level != Logger::UNKNOWN
  end
end
