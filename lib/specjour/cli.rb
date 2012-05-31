module Specjour
  require 'thor'
  class CLI < Thor

    def self.worker_option
      method_option :workers, :aliases => "-w", :type => :numeric, :desc => "Number of concurent processes to run. Defaults to your system's available cores."
    end

    def self.dispatcher_option
      method_option :alias, :aliases => "-a", :desc => "Project name advertised to listeners"
    end

    def self.rsync_port_option
      method_option :rsync_port, :type => :numeric, :default => 23456, :desc => "Port to use for rsync daemon"
    end

    # allow specjour to be called with path arguments
    def self.start(original_args=ARGV, config={})
      Specjour.trap_interrupt
      real_tasks = all_tasks.keys | @map.keys
      unless real_tasks.include? original_args.first
        original_args.unshift default_task
      end
      super(original_args)
    end

    default_task :dispatch

    class_option :log, :aliases => "-l", :type => :boolean, :desc => "Print debug messages to $stderr"

    desc "listen", "Listen for incoming tests to run"
    long_desc <<-DESC
      Advertise availability to run tests for the current directory.
    DESC
    worker_option
    rsync_port_option
    method_option :projects, :aliases => "-p", :type => :array, :desc => "Projects supported by this listener"
    def listen
      handle_logging
      handle_workers
      params[:registered_projects] = params.delete(:projects) || [File.basename(Dir.pwd)]
      append_to_program_name "listen"
      Specjour::Manager.new(params).start
    end

    desc "load", "load the app, then fork workers", :hide => true
    worker_option
    method_option :printer_uri, :required => true
    method_option :project_path, :required => true
    method_option :task, :required => true
    method_option :test_paths, :type => :array, :default => []
    method_option :quiet, :type => :boolean, :default => false
    def load
      handle_logging
      handle_workers
      append_to_program_name "load"
      Specjour::Loader.new(params).start
    end

    desc "dispatch [test_paths]", "Send tests to a listener"
    worker_option
    dispatcher_option
    rsync_port_option
    long_desc <<-DESC
      This is run when you simply type `specjour`.
      By default, it will run the specs and features found in the current directory.
      If you like, you can run a subset of tests by specifying the folder containing the tests.\n
      Examples\n
      `specjour dispatch spec`\n
      `specjour dispatch features`\n
      `specjour dispatch spec/models features/sign_up.feature`\n
    DESC
    def dispatch(*paths)
      handle_logging
      handle_workers
      handle_dispatcher(paths)
      append_to_program_name "dispatch"
      Specjour::Dispatcher.new(params).start
    end

    desc "prepare [PROJECT_PATH]", "Run the prepare task on all listening workers"
    long_desc <<-DESC
      Run the Specjour::Configuration.prepare block on all listening workers.
      Defaults to dropping the database, then loading the schema.
    DESC
    worker_option
    dispatcher_option
    rsync_port_option
    def prepare(path = Dir.pwd)
      handle_logging
      handle_workers
      params[:project_path] = File.expand_path(path)
      params[:project_alias] = params.delete(:alias)
      params[:test_paths] = []
      params[:worker_task] = 'prepare'
      append_to_program_name "prepare"
      Specjour::Dispatcher.new(params).start
    end

    map %w(-v --version) => :version
    desc "version", "Show the current version"
    def version
      puts Specjour::VERSION
    end

    protected

    def append_to_program_name(command)
      $PROGRAM_NAME = "#{$PROGRAM_NAME} #{command}"
    end

    def params
      @params ||= options.dup
    end

    def handle_logging
      Specjour.new_logger(Logger::DEBUG) if options['log']
    end

    def handle_workers
      params[:worker_size] = options["workers"] || CPU.cores
    end

    def handle_dispatcher(paths)
      if paths.empty?
        params[:project_path] = Dir.pwd
      else
        params[:project_path] = File.expand_path(paths.first.sub(/(spec|features).*$/, ''))
      end
      params[:test_paths] = paths
      params[:project_alias] = params.delete(:alias)
      raise ArgumentError, "Cannot dispatch line numbers" if paths.any? {|p| p =~ /:\d+/}
    end
  end
end
