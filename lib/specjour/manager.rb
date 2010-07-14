module Specjour
  class Manager
    require 'dnssd'
    require 'specjour/rspec'
    require 'specjour/cucumber'

    include DRbUndumped
    include SocketHelper

    attr_accessor :project_name, :preload_spec, :preload_feature, :worker_task, :pid
    attr_reader :worker_size, :dispatcher_uri, :registered_projects, :bonjour_service, :worker_pids, :options

    def self.start_quietly(options)
      manager = new options.merge(:quiet => true)
      manager.drb_uri
      manager.pid = QuietFork.fork { manager.start }
      manager
    end

    def initialize(options = {})
      @options = options
      @worker_size = options[:worker_size]
      @worker_task = options[:worker_task]
      @registered_projects = options[:registered_projects]
      @worker_pids = []
      at_exit { kill_worker_processes }
    end

    def available_for?(project_name)
      registered_projects ? registered_projects.include?(project_name) : false
    end

    def dispatcher_uri=(uri)
      uri.host = ip_from_hostname(uri.host)
      @dispatcher_uri = uri
    end

    def dispatch
      suspend_bonjour do
        sync
        execute_before_fork
        dispatch_workers
      end
    end

    def drb_start
      DRb.start_service drb_uri.to_s, self
      at_exit { DRb.stop_service }
    end

    def drb_uri
      @drb_uri ||= begin
        current_uri.scheme = "druby"
        current_uri
      end
    end

    def dispatch_workers
      worker_pids.clear
      (1..worker_size).each do |index|
        worker_pids << fork do
          exec "specjour work #{worker_options(index)}"
        end
      end
      Process.waitall
    end

    def in_project(&block)
      Dir.chdir(project_path, &block)
    end

    def kill_worker_processes
      Process.kill('TERM', *worker_pids) rescue Errno::ESRCH
    end

    def pid
      @pid || Process.pid
    end

    def project_path
      File.join("/tmp", project_name)
    end

    def start
      drb_start
      puts "Workers ready: #{worker_size}."
      puts "Listening for #{registered_projects.join(', ')}"
      bonjour_announce
      Signal.trap('INT') { puts; puts "Shutting down manager..."; exit 1 }
      DRb.thread.join
    end

    def quiet?
      options.has_key? :quiet
    end

    def sync
      cmd "rsync -aL --delete --port=8989 #{dispatcher_uri.host}::#{project_name} #{project_path}"
    end

    protected

    def bonjour_announce
      @bonjour_service = DNSSD.register! "specjour_manager_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end

    def cmd(command)
      puts command
      system command
    end

    def execute_before_fork
      in_project do
        Specjour.load_custom_hooks
        Configuration.before_fork.call
      end
    end

    def suspend_bonjour(&block)
      bonjour_service.stop
      block.call
      bonjour_announce
    end

    def worker_options(index)
      exec_options = "--project-path #{project_path} --printer-uri #{dispatcher_uri} --number #{index} --task #{worker_task}"
      exec_options << " --preload-spec #{preload_spec}" if preload_spec
      exec_options << " --preload-feature #{preload_feature}" if preload_feature
      exec_options << " --log" if Specjour.log?
      exec_options << " --quiet" if quiet?
      exec_options
    end
  end
end
