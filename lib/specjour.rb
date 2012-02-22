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
  autoload :Fork, 'specjour/fork'
  autoload :Loader, 'specjour/loader'
  autoload :Manager, 'specjour/manager'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelper, 'specjour/socket_helper'
  autoload :Worker, 'specjour/worker'

  autoload :Cucumber, 'specjour/cucumber'
  autoload :RSpec, 'specjour/rspec'

  VERSION ||= "0.5.2"
  HOOKS_PATH ||= "./.specjour/hooks.rb"
  PROGRAM_NAME ||= $PROGRAM_NAME # keep a reference of the original program name

  GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

  class Error < StandardError; end

  def self.interrupted?
    @interrupted
  end

  def self.interrupted=(bool)
    @interrupted = bool
    if bool
      will_quit(:RSpec)
      will_quit(:Cucumber)
    end
  end

  def self.will_quit(framework)
    if Object.const_defined?(framework)
      framework = Object.const_get(framework)
      framework.wants_to_quit = true if framework.respond_to?(:wants_to_quit=)
    end
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

  def self.trap_interrupt
    Signal.trap('INT') do
      self.interrupted = true
      abort("\n")
    end
  end
end
