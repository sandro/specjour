require 'drb'

autoload :URI, 'uri'
autoload :Forwardable, 'forwardable'
autoload :GServer, 'gserver'
autoload :Timeout, 'timeout'
autoload :Benchmark, 'benchmark'
autoload :Logger, 'logger'
autoload :Socket, 'socket'

module Specjour
  autoload :CLI, 'specjour/cli'
  autoload :CPU, 'specjour/cpu'
  autoload :Connection, 'specjour/connection'
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :Manager, 'specjour/manager'
  autoload :OpenStruct, 'ostruct'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelper, 'specjour/socket_helper'
  autoload :Worker, 'specjour/worker'

  autoload :Cucumber, 'specjour/cucumber'
  autoload :Rspec, 'specjour/rspec'

  VERSION = "0.2.5".freeze

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

  Error = Class.new(StandardError)

  GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
end
