module Specjour
  require 'thor'
  class CLI < Thor

    def self.worker_option
      method_option :workers, :aliases => "-w", :type => :numeric, :desc => "Number of concurent processes to run. Defaults to your system's available cores."
    end

    def self.dispatcher_option
      method_option :alias, :aliases => "-a", :desc => "Project name advertised to listeners"
    end

    def self.start(original_args=ARGV, config={})
      real_tasks = all_tasks.keys | HELP_MAPPINGS
      unless real_tasks.include? original_args.first
        original_args.unshift default_task
      end
      super(original_args)
    end


    default_task :dispatch

    class_option :log, :aliases => "-l", :type => :boolean, :desc => "Print debug messages to $stderr"


    desc "listen", "Wait for incoming tests"
    long_desc <<-D
      Advertise availability to run tests for the current directory.
    D
    worker_option
    method_option :projects, :aliases => "-p", :type => :array, :desc => "Projects supported by this listener"
    def listen
      handle_logging
      handle_workers
      args[:registered_projects] = args.delete(:projects) || [File.basename(Dir.pwd)]
      append_to_program_name "listen"
      Specjour::Manager.new(args).start
    end

    desc "dispatch [PROJECT_PATH]", "Run tests in the current directory"
    worker_option
    dispatcher_option
    def dispatch(path = Dir.pwd)
      handle_logging
      handle_workers
      handle_dispatcher(path)
      append_to_program_name "dispatch"
      Specjour::Dispatcher.new(args).start
    end

    desc "prepare [PROJECT_PATH]", "Prepare all listening workers"
    long_desc <<-D
      Run the Specjour::Configuration.prepare block on all listening workers.
      Defaults to dropping and schema loading the database.
    D
    worker_option
    dispatcher_option
    def prepare(path = Dir.pwd)
      handle_logging
      handle_workers
      handle_dispatcher(path)
      args[:worker_task] = 'prepare'
      append_to_program_name "prepare"
      Specjour::Dispatcher.new(args).start
    end

    desc "version", "Show the current version"
    def version
      puts Specjour::VERSION
    end

    protected

    def append_to_program_name(command)
      $PROGRAM_NAME = "#{$PROGRAM_NAME} #{command}"
    end

    def args
      @args ||= options.dup
    end

    def handle_logging
      Specjour.new_logger(Logger::DEBUG) if options['log']
    end

    def handle_workers
      args[:worker_size] = options["workers"] || CPU.cores
    end

    def handle_dispatcher(path)
      args[:project_path] = path
      args[:project_alias] = args.delete(:alias)
    end
  end
end
