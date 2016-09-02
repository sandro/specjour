module Specjour
  require 'optparse'
  class CLI
    include Logger

    COMMANDS = %w(listen tester ls stop)

    attr_accessor :options

    def initialize
      self.options = {}
    end

    def start
      Specjour.trap_interrupt_with_exit
      parser.parse!
      append_to_program_name(ARGV[0])
      case ARGV[0]
      when "listen"
        listener = Listener.new
        if listener.started?
          listener.stop
        end
        listener.daemonize unless options[:foreground]
        listener.start
      when "tester"
        Tester.new("FOUR").start
      when "ls"
        puts "Plugins:"
        puts Specjour.plugin_manager.plugins
      when "stop"
        listener = Listener.new
        if listener.started?
          puts "Stopping listener with pid #{listener.pid}"
          listener.stop
        else
          abort("No listener found")
        end
      when "help"
        abort("Commands are: #{COMMANDS.join(" ")}")
      else
        test_paths = ARGV[0..-1]
        if no_workers?
          listener = Listener.new
          listener.stop if listener.started?
        else
          Listener.ensure_started
        end
        printer = nil
        printer = Printer.new test_paths: Array(test_paths)
        printer.announce
        printer.start_rsync
        printer.start
      end
    end

    def no_workers?
      options[:workers] && options[:workers] <= 0
    end

    def parser
      @parser ||= OptionParser.new do |parser|
        parser.banner = "Usage: specjour [command] [options] [files or directories]\n\nCommands are #{COMMANDS.join(",")}\n\n"

        parser.on('-b', '--backtrace', 'Enable full backtrace.') do |o|
          options[:full_backtrace] = true
          Specjour.configuration.full_backtrace = true
        end

        parser.on("-l", "--log [FILE]", String, "Print logging information") do |option|
          Specjour.new_logger ::Logger::INFO, option
        end

        parser.on("-d", "--debug [FILE]", String, "Print debugging information") do |option|
          Specjour.new_logger ::Logger::DEBUG, option
        end

        parser.on("-f", "--foreground", "Foreground the listener (development purposes)") do |option|
          options[:foreground] = option
        end

        parser.on("-w", "--workers NUM", Numeric, "Number of workers") do |option|
          options[:workers] = option.to_i
          Specjour.configuration.worker_size = options[:workers]
        end

        parser.on("-a", "--alias NAME", Array, "Project name alias") do |option|
          Specjour.configuration.project_aliases = option
        end

        parser.on("-v", "--version", "Version number") do |option|
          puts Specjour::VERSION
          exit
        end
      end
    end

    private

    def append_to_program_name(command)
      $PROGRAM_NAME = "#{$PROGRAM_NAME} #{command}"
    end
  end
end
