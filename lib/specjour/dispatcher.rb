module Specjour
  class Dispatcher
    include DRbUndumped
    attr_reader :project_path, :workers, :worker_threads, :hosts

    def initialize(project_path)
      @project_path = project_path
      @workers = []
      @hosts = {}
      reset_worker_threads
    end

    def all_specs
      @all_specs ||= Dir.chdir(project_path) do
        Dir["spec/**/*_spec.rb"].sort_by { rand }
      end
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def start
      rsync_daemon.start
      drb_start
      gather_workers
      sync_workers
      dispatch_work
      report.summarize
    end

    def add_to_report(stats)
      report.add(stats)
    end

    def report
      @report ||= FinalReport.new
    end

    def stderr
      @stderr ||= $stderr
    end

    def stdout
      @stdout ||= $stdout
    end

    protected

    def add_worker_to_hosts(worker, host)
      if hosts[host]
        hosts[host] << worker
      else
        hosts[host] = [worker]
      end
    end

    def dispatch_work
      workers.each_with_index do |worker, index|
        worker.specs_to_run = Array(specs_for_worker(index))
        worker_threads << Thread.new(worker, &work)
      end
      wait_on_workers
    end

    def drb_start
      DRb.start_service nil, self
      at_exit { puts 'shutting down DRb client'; DRb.stop_service }
    end

    def fetch_worker(uri)
      worker = DRbObject.new_with_uri(uri.to_s)
      add_worker_to_hosts(worker, uri.host)
      worker.project_name = project_name
      worker.host = hostname
      worker.number = hosts[uri.host].index(worker) + 1
      worker.dispatcher_uri = DRb.uri
      worker
    end

    def gather_workers
      browser = DNSSD::Service.new
      puts 'browsing'
      browser.browse '_druby._tcp' do |reply|
        if reply.flags.add?
          DNSSD.resolve!(reply) do |resolved|
            uri = URI::Generic.build :scheme => reply.service_name, :host => resolved.target, :port => resolved.port
            workers << fetch_worker(uri)
            resolved.service.stop
          end
        end
        browser.stop unless reply.flags.more_coming?
      end
      puts "Workers found: #{workers.size}"
    end

    def hostname
      @hostname ||= %x(hostname).strip
    end

    def reset_worker_threads
      @worker_threads = []
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
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

    def specs_per_worker
      per = all_specs.size / workers.size
      per.zero? ? 1 : per
    end

    def sync_workers
      hosts.each do |hostname, workers|
        worker_threads << Thread.new(workers.first) { |worker| worker.sync }
      end
      wait_on_workers
    end

    def wait_on_workers
      worker_threads.each {|t| t.join}
      reset_worker_threads
    end

    def work
      lambda do |worker|
        worker.run
      end
    end
  end
end
