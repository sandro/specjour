require 'drb'

autoload :URI, 'uri'
autoload :Forwardable, 'forwardable'
autoload :GServer, 'gserver'
autoload :Timeout, 'timeout'
autoload :Benchmark, 'benchmark'
autoload :Logger, 'logger'
autoload :Socket, 'socket'

module Specjour
  autoload :CPU, 'specjour/cpu'
  autoload :Connection, 'specjour/connection'
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :Manager, 'specjour/manager'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelpers, 'specjour/socket_helpers'
  autoload :Worker, 'specjour/worker'

  autoload :Cucumber, 'specjour/cucumber'
  autoload :Rspec, 'specjour/rspec'

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
