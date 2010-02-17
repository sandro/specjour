module Specjour
  class Dispatcher
    attr_reader :project_path, :workers, :worker_threads

    def initialize(project_path)
      @project_path = project_path
      @workers = []
      @worker_threads = []
    end

    def all_specs
      @all_specs ||= Dir[File.join(project_path, "/spec/**/*_spec.rb")]
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
      workers.each_with_index do |worker, index|
        worker.specs_to_run = Array(specs_for_worker(index))
        worker_threads << Thread.new(worker, &work)
      end
    end

    def gather_workers
      browser.browse '_druby._tcp' do |reply|
        DNSSD.resolve(reply) do |resolved|
          uri = URI::Generic.build :scheme => reply.service_name, :host => resolved.target, :port => resolved.port
          workers << fetch_worker(uri)
          reply.service.stop unless reply.flags.more_coming?
        end
      end
      p workers
    end

    def fetch_worker(uri)
      worker = DRbObject.new_with_uri(uri.to_s)
      worker.project_path = project_path
      worker.project_name = project_name
      worker
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def specs_per_worker
      per = all_specs.size / workers.size
      per.zero? ? 1 : per
    end

    def specs_for_worker(index)
      offset = (index * specs_per_worker)
      boundry = specs_per_worker * (index + 1)
      range = (offset...boundry)
      if workers[index] == workers.last
        range = (offset..-1)
      end
      all_specs[range]
    end

    def wait_on_workers
      worker_threads.each {|t| t.join}
    end

    def work
      lambda do |worker|
        puts worker.run
      end
    end
  end
end
