module Specjour
  class Manager
    require 'dnssd'
    include DRbUndumped

    attr_accessor :project_name, :specs_to_run, :dispatcher_uri, :worker_size, :bonjour_service, :batch_size

    def initialize(worker_size = 1, batch_size = 1)
      @worker_size = worker_size
      @batch_size = batch_size
    end

    def bundle_install
      Dir.chdir(project_path) do
        unless system('bundle check > /dev/null')
          system("bundle install --relock > /dev/null")
        end
      end
    end

    def project_path
      File.join("/tmp", project_name)
    end

    def dispatch
      bonjour_service.stop
      pids = []
      (1..worker_size).each do |index|
        pids << fork do
          exec("specjour --batch-size #{batch_size} --do-work #{project_path},#{dispatcher_uri},#{index},#{specs_to_run[index - 1].join(',')}")
          Kernel.exit!
        end
      end
      at_exit { Process.kill('KILL', *pids) rescue nil }
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
      cmd "rsync -a --port=8989 #{dispatcher_uri.host}::#{project_name} #{project_path}"
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
