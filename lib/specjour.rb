require 'tmpdir'

autoload :URI, 'uri'
autoload :Forwardable, 'forwardable'
autoload :Timeout, 'timeout'
autoload :Benchmark, 'benchmark'
autoload :Logger, 'logger'
autoload :Socket, 'socket'
autoload :StringIO, 'stringio'
autoload :OpenStruct, 'ostruct'
autoload :Pathname, 'pathname'

module Specjour
  autoload :CLI, 'specjour/cli'
  autoload :Colors, 'specjour/colors'
  autoload :CPU, 'specjour/cpu'
  autoload :Configuration, 'specjour/configuration'
  autoload :Connection, 'specjour/connection'
  autoload :DbScrub, 'specjour/db_scrub'
  autoload :Dispatcher, 'specjour/dispatcher'
  autoload :Fork, 'specjour/fork'
  autoload :Formatter, 'specjour/formatter'
  autoload :Listener, 'specjour/listener'
  autoload :Logger, 'specjour/logger'
  autoload :Loader, 'specjour/loader'
  autoload :Manager, 'specjour/manager'
  autoload :Plugin, 'specjour/plugin'
  autoload :Printer, 'specjour/printer'
  autoload :Protocol, 'specjour/protocol'
  autoload :RspecFormatter, "specjour/rspec_formatter"
  autoload :RsyncDaemon, 'specjour/rsync_daemon'
  autoload :SocketHelper, 'specjour/socket_helper'
  autoload :Tester, 'specjour/tester'
  autoload :Worker, 'specjour/worker'

  autoload :Cucumber, 'specjour/cucumber'
  autoload :RSpec, 'specjour/rspec'

  VERSION ||= "0.7.0"
  HOOKS_PATH ||= "./.specjour/hooks.rb"
  PROGRAM_NAME ||= $PROGRAM_NAME # keep a reference of the original program name
  Time = Time.dup

  GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

  class Error < StandardError; end

  def self.benchmark(msg)
    $stderr.print "#{msg}... "
    return_value = nil
    time = Benchmark.realtime do
      return_value = yield
    end
    $stderr.puts "completed in #{time}s"
    return_value
  end

  def self.configuration(provided_config=nil)
    if provided_config
      @configuration = provided_config
    elsif !instance_variable_defined?(:@configuration)
      @configuration = Configuration.new
    else
      @configuration
    end
  end

  def self.interrupted?
    @interrupted
  end

  def self.interrupted=(bool)
    @interrupted = bool
  end

  def self.load_custom_hooks
    load HOOKS_PATH if File.exists?(HOOKS_PATH)
  end

  def self.load_plugins
    $LOAD_PATH.each do |load_path|
      file = File.expand_path("specjour_plugin.rb", load_path)
      require file if File.exists?(file)
    end
    return
  end

  def self.logger
    @logger ||= new_logger
 end

  def self.new_logger(level = ::Logger::UNKNOWN, output=nil)
    @logger = ::Logger.new output || $stderr
    @logger.level = level
    @logger.formatter = lambda do |severity, datetime, progname, message|
      "[#{severity} #{datetime.strftime("%I:%M:%S")}] #{progname}: #{message}\n"
    end
    @logger
  end

  def self.plugin_manager
    @plugin_manager ||= Specjour::Plugin::Manager.new
  end

  def self.trap_interrupt
    Signal.trap('INT') do
      self.interrupted = true
      plugin_manager.send_task(:interrupted!)
    end
  end

  def self.trap_interrupt_with_exit
    trap_interrupt
    old_int = Signal.trap("INT") do
      old_int.call()
      abort("ABORTING\n")
    end
  end
end
