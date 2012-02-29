module Specjour
  class Manager
    require 'dnssd'

    include DRbUndumped
    include SocketHelper
    include Fork

    attr_accessor :test_paths, :project_name, :worker_task, :pid
    attr_reader :worker_size, :dispatcher_uri, :registered_projects, :loader_pid, :options, :rsync_port

    def self.start_quietly(options)
      manager = new options.merge(:quiet => true)
      manager.drb_uri
      manager.pid = Fork.fork_quietly { manager.start }
      manager
    end

    def initialize(options = {})
      @options = options
      @worker_size = options[:worker_size]
      @worker_task = options[:worker_task]
      @registered_projects = options[:registered_projects]
      @rsync_port = options[:rsync_port]
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
        with_clean_env do
          execute_before_fork
          dispatch_loader
        end
      end
    end

    def drb_start
      $PROGRAM_NAME = "specjour listen" if quiet?
      DRb.start_service drb_uri.to_s, self
      at_exit { DRb.stop_service }
    end

    def drb_uri
      @drb_uri ||= begin
        current_uri.scheme = "druby"
        current_uri
      end
    end

    def dispatch_loader
      @loader_pid = fork do
        exec_cmd = "load --printer-uri #{dispatcher_uri} --workers #{worker_size} --task #{worker_task} --project-path #{project_path}"
        exec_cmd << " --test-paths #{test_paths.join(" ")}" if test_paths.any?
        exec_cmd << " --log" if Specjour.log?
        exec_cmd << " --quiet" if quiet?
        load_path = $LOAD_PATH.detect {|l| l =~ %r(specjour[^/]*/lib$)}
        bin_path = File.expand_path(File.join(load_path, "../bin"))
        Kernel.exec({"RUBYLIB" => load_path}, "#{bin_path}/specjour #{exec_cmd}")
      end
      Process.waitall
    ensure
      kill_loader_process if loader_pid
    end

    def in_project(&block)
      Dir.chdir(project_path, &block)
    end

    def interrupted=(bool)
      Specjour.interrupted = bool
      kill_loader_process if loader_pid
    end

    def kill_loader_process
      if Specjour.interrupted?
        Process.kill('INT', loader_pid) rescue Errno::ESRCH
      else
        Process.kill('TERM', loader_pid) rescue Errno::ESRCH
      end
      @loader_pid = nil
    end

    def pid
      @pid || Process.pid
    end

    def project_path
      File.join("/tmp", project_name)
    end

    def start
      drb_start
      bonjour_announce
      at_exit { stop_bonjour }
      DRb.thread.join
    end

    def quiet?
      options.has_key? :quiet
    end

    def sync
      cmd "rsync -aL --delete --ignore-errors --port=#{rsync_port} #{dispatcher_uri.host}::#{project_name} #{project_path}"
      puts "rsync complete"
    end

    protected

    def bonjour_announce
      projects = registered_projects.join(", ")
      puts "Workers ready: #{worker_size}"
      puts "Listening for #{projects}"
      unless quiet?
        text = DNSSD::TextRecord.new
        text['version'] = Specjour::VERSION
        bonjour_service.register "specjour_manager_#{projects}_#{Process.pid}", "_#{drb_uri.scheme}._tcp", domain=nil, drb_uri.port, host=nil, text
      end
    end

    def bonjour_service
      @bonjour_service ||= DNSSD::Service.new
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

    def stop_bonjour
      bonjour_service.stop if bonjour_service && !bonjour_service.stopped?
      @bonjour_service = nil
    end

    def suspend_bonjour(&block)
      stop_bonjour
      block.call
      bonjour_announce
    end

    def with_clean_env
      if defined?(Bundler)
        Bundler.with_clean_env do
          if ENV['RUBYOPT']
            opts = ENV['RUBYOPT'].split(" ").delete_if {|opt| opt =~ /bundler/}
            ENV['RUBYOPT'] = opts.join(" ")
          end
          yield
        end
      else
        yield
      end
    end
  end
end
