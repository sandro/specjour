module Specjour
  class Manager
    require 'dnssd'
    include DRbUndumped
    include SocketHelper

    attr_accessor :project_name, :specs_to_run
    attr_reader :worker_size, :dispatcher_uri, :registered_projects, :bonjour_service, :worker_pids

    def initialize(options = {})
      @worker_size = options[:worker_size]
      @registered_projects = options[:registered_projects]
      @worker_pids = []
      at_exit { kill_worker_processes }
    end

    def available_for?(project_name)
      registered_projects ? registered_projects.include?(project_name) : false
   end

    def bundle_install
      Dir.chdir(project_path) do
        unless system('bundle check > /dev/null')
          system("bundle install --relock > /dev/null")
        end
      end
    end

    def dispatcher_uri=(uri)
      uri.host = ip_from_hostname(uri.host)
      @dispatcher_uri = uri
    end

    def kill_worker_processes
      Process.kill('TERM', *worker_pids) rescue Errno::ESRCH
    end

    def project_path
      File.join("/tmp", project_name)
    end

    def dispatch
      suspend_bonjour do
        sync
        bundle_install
        dispatch_workers
      end
    end

    def dispatch_workers
      worker_pids.clear
      (1..worker_size).each do |index|
        worker_pids << fork do
          exec("specjour work --project-path #{project_path} --printer-uri #{dispatcher_uri} --number #{index} #{'--log' if Specjour.log?}")
          Kernel.exit!
        end
      end
      Process.waitall
    end

    def start
      drb_start
      puts "Workers ready: #{worker_size}."
      puts "Listening for #{registered_projects.join(', ')}"
      bonjour_announce
      Signal.trap('INT') { puts; puts "Shutting down manager..."; exit }
      DRb.thread.join
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

    def suspend_bonjour(&block)
      bonjour_service.stop
      block.call
      bonjour_announce
    end
  end
end
