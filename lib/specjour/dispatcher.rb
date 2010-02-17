module Specjour
  class Dispatcher
    attr_reader :project_path, :workers, :worker_threads

    def initialize(project_path)
      @project_path = project_path
      @workers = []
      @worker_threads = []
    end

    def alert_clients

    end

    def project_name
      File.basename(project_path)
    end

    def serve
      rsync_daemon.start
    end

    def start
      gather_workers
      dispatch_work
      wait_on_workers
    end

    protected

    def browser
      @browser ||= DNSSD::Service.new
    end

    def dispatch_work
      workers.each do |worker|
        worker_threads << Thread.new(worker, &work)
      end
    end

    def gather_workers
      browser.browse '_druby._tcp' do |reply|
        DNSSD.resolve(reply) do |resolved|
          uri = URI::Generic.build :scheme => reply.service_name, :host => resolved.target, :port => resolved.port
          workers << DRbObject.new_with_uri(uri.to_s)
          reply.service.stop
        end
      end
      workers
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def wait_on_workers
      worker_threads.each {|t| t.join}
    end

    def work
      lambda do |worker|
        puts worker.run("spec/")
      end
    end
  end
end
