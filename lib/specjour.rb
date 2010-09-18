require 'drb'

autoload :URI, 'uri'
autoload :Forwardable, 'forwardable'
autoload :GServer, 'gserver'
autoload :Timeout, 'timeout'
autoload :Benchmark, 'benchmark'
autoload :Logger, 'logger'
autoload :Socket, 'socket'
autoload :StringIO, 'stringio'
autoload :OpenStruct, 'ostruct'

module Specjour
  autoload :CLI, 'specjour/cli'
  autoload :CPU, 'specjour/cpu'
  autoload :Configuration, 'specjour/configuration'
  autoload :Connection, 'specjour/connection'
  autoload :DbScrub, 'specjour/db_scrub'
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :Manager, 'specjour/manager'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'
  autoload :QuietFork, 'specjour/quiet_fork'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelper, 'specjour/socket_helper'
  autoload :Worker, 'specjour/worker'

  autoload :Cucumber, 'specjour/cucumber'
  autoload :Rspec, 'specjour/rspec'

  VERSION = "0.3.0.rc8".freeze
  HOOKS_PATH = "./.specjour/hooks.rb"

  class << self
    attr_accessor :interrupted
    alias interrupted? interrupted
  end

  def self.logger
    @logger ||= new_logger
  end

  def self.new_logger(level = Logger::UNKNOWN)
    @logger = Logger.new $stderr
    @logger.level = level
    @logger
  end

  def self.log?
    logger.level != Logger::UNKNOWN
  end

  def self.load_custom_hooks
    require HOOKS_PATH if File.exists?(HOOKS_PATH)
  end

  Error = Class.new(StandardError)
  PROGRAM_NAME = $PROGRAM_NAME # keep a reference of the original program name

  GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

  Signal.trap('INT') { Specjour.interrupted = true; exit 1 }
end
