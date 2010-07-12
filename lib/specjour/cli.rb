module Specjour
  require 'thor'
  class CLI < Thor

    def self.printable_tasks
      super.reject{|t| t.last =~ /INTERNAL USE/ }
    end

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

    desc "listen", "Advertise availability to run specs\nDefaults to current directory"
    worker_option
    method_option :projects, :aliases => "-p", :type => :array, :desc => "Projects supported by this listener"
    def listen
      handle_logging
      handle_workers
      args[:registered_projects] = args.delete(:projects) || [File.basename(Dir.pwd)]
      Specjour::Manager.new(args).start
    end

    desc "dispatch [PROJECT_PATH]", "Run specs in this project"
    worker_option
    dispatcher_option
    def dispatch(path = Dir.pwd)
      handle_logging
      handle_workers
      handle_dispatcher(path)
      Specjour::Dispatcher.new(args).start
    end

    desc "prepare [PROJECT_PATH]", "Run the prepare block on all listening workers"
    worker_option
    dispatcher_option
    def prepare(path = Dir.pwd)
      handle_logging
      handle_workers
      handle_dispatcher(path)
      args[:worker_task] = 'prepare'
      Specjour::Dispatcher.new(args).start
    end

    desc "version", "Show the version of specjour"
    def version
      puts Specjour::VERSION
    end

    desc "work", "INTERNAL USE ONLY"
    method_option :project_path, :required => true
    method_option :printer_uri, :required => true
    method_option :number, :type => :numeric, :required => true
    method_option :preload_spec
    method_option :preload_feature
    method_option :task, :required => true
    method_option :quiet, :type => :boolean
    def work
      handle_logging
      Specjour::Worker.new(args).start
    end

    protected

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
