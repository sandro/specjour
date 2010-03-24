module Specjour
  class Manager
    require 'dnssd'
    include DRbUndumped

    attr_accessor :project_name, :specs_to_run, :dispatcher_uri
    attr_reader :worker_size, :batch_size, :registered_dispatcher, :bonjour_service, :worker_pids

    def initialize(options = {})
      @worker_size = options[:worker_size]
      @batch_size = options[:batch_size]
      @registered_dispatcher = options[:registered_dispatcher]
      @worker_pids = []
    end

    def available_for?(hostname)
      registered_dispatcher ? registered_dispatcher == hostname : true
   end

    def bundle_install
      Dir.chdir(project_path) do
        unless system('bundle check > /dev/null')
          system("bundle install --relock > /dev/null")
        end
      end
    end

    def kill_worker_processes
      Process.kill('TERM', *worker_pids) rescue nil
    end

    def project_path
      File.join("/tmp", project_name)
    end

    def dispatch
      bonjour_service.stop
      (1..worker_size).each do |index|
        worker_pids << fork do
          exec("specjour --batch-size #{batch_size} --do-work #{project_path},#{dispatcher_uri},#{index},#{specs_to_run[index - 1].join(',')}")
          Kernel.exit!
        end
      end
      at_exit { kill_worker_processes }
      Process.waitall
      bonjour_announce
    end

    def start
      drb_start
      bonjour_announce
      Signal.trap('INT') { puts; puts "Shutting down manager..."; exit }
      DRb.thread.join
    end

    def drb_start
      DRb.start_service nil, self
      Kernel.puts "Manager started at #{drb_uri}"
      at_exit { DRb.stop_service }
    end

    def sync
      cmd "rsync -a --delete --port=8989 #{dispatcher_uri.host}::#{project_name} #{project_path}"
    end

    protected

    def cmd(command)
      Kernel.puts command
      system command
    end

    def drb_uri
      @drb_uri ||= URI.parse(DRb.uri)
    end

    def bonjour_announce
      @bonjour_service = DNSSD.register! "specjour_manager_#{object_id}", "_#{drb_uri.scheme}._tcp", nil, drb_uri.port
    end
  end
end
