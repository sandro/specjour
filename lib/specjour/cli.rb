module Specjour
  require 'optparse'
  class CLI
    include Logger

    COMMANDS = %w(listen ls stop)

    attr_accessor :options

    def initialize
      self.options = {}
    end

    def stop_running_listener
      listener = Listener.new
      if listener.started?
        listener.stop
      end
      listener
    end

    def start
      Specjour.trap_interrupt_with_exit
      parser.parse!
      append_to_program_name(ARGV[0])
      ensure_alias
      case ARGV[0]
      when "listen"
        listener = stop_running_listener
        listener.daemonize unless options[:foreground]
        listener.start
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
        if options[:workers]
          stop_running_listener
          if options[:workers] > 0
            Listener.ensure_started
          end
        else
          Listener.ensure_started
        end
        printer = Printer.new test_paths: Array(test_paths)
        printer.announce
        printer.start_rsync
        printer.start
      end
    end

    def ensure_alias
      if Specjour.configuration.project_aliases.empty?
        Specjour.configuration.project_aliases = [File.basename(Dir.pwd)]
      end
    end

    def parser
      @parser ||= OptionParser.new do |parser|
        parser.banner = "Usage: specjour [command] [options] [files or directories]\n\nCommands are #{COMMANDS.join(",")}\n\n"

        parser.on('-b', '--backtrace', 'Include specjour in the backtrace (do not scrub backtrace)') do |o|
          options[:full_backtrace] = true
          Specjour.configuration.full_backtrace = true
        end

        parser.on("-l", "--log", "Enable informational logging") do
          Specjour.new_logger ::Logger::INFO
        end

        parser.on("-d", "--debug", "Enable debug logging") do
          Specjour.new_logger ::Logger::DEBUG
        end

        parser.on("-f", "--foreground", "Foreground the listener") do |option|
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
