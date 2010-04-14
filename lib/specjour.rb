require 'spec'
require 'spec/runner/formatter/base_text_formatter'
require 'specjour/protocol'
require 'specjour/core_ext/array'

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
  autoload :DistributedFormatter, 'specjour/distributed_formatter'
  autoload :FinalReport, 'specjour/final_report'
  autoload :Manager, 'specjour/manager'
  autoload :MarshalableFailureFormatter, 'specjour/marshalable_failure_formatter'
  autoload :Printer, 'specjour/printer'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :Worker, 'specjour/worker'

  VERSION = "0.1.12".freeze

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

  def self.ip_from_hostname(hostname)
    Socket.getaddrinfo(hostname, nil).last.fetch(3)
  end
end
