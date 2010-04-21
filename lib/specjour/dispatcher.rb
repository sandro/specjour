module Specjour
  class Dispatcher
    require 'dnssd'
    Thread.abort_on_exception = true
    include SocketHelpers

    class << self
      attr_accessor :interrupted
      alias interrupted? interrupted
    end

    attr_reader :project_path, :managers, :manager_threads, :hosts
    attr_accessor :worker_size

    def initialize(project_path)
      @project_path = project_path
      @managers = []
      @worker_size = 0
      reset_manager_threads
    end

    def start
      rsync_daemon.start
      gather_managers
      dispatch_work
      printer.join
    end

    protected

    def all_specs
      @all_specs ||= Dir.chdir(project_path) do
        Dir["spec/**/**/*_spec.rb"].sort
      end
    end

    def command_managers(async = false, &block)
      managers.each do |manager|
        manager_threads << Thread.new(manager, &block)
      end
      wait_on_managers unless async
    end

    def dispatch_work
      command_managers(true) { |m| m.dispatch }
    end

    def fetch_manager(uri)
      Timeout.timeout(8) do
        manager = DRbObject.new_with_uri(uri.to_s)
        if !managers.include?(manager) && manager.available_for?(project_name)
          set_up_manager(manager, uri)
          managers << manager
          self.worker_size += manager.worker_size
        end
      end
    rescue Timeout::Error
      Specjour.logger.debug "Couldn't work with manager at #{uri}"
    end

    def gather_managers
      puts "Waiting for managers"
      Signal.trap('INT') { self.class.interrupted = true; exit }
      browser = DNSSD::Service.new
      begin
        Timeout.timeout(10) do
          browser.browse '_druby._tcp' do |reply|
            if reply.flags.add?
              resolve_reply(reply)
            end
            browser.stop unless reply.flags.more_coming?
          end
        end
      rescue Timeout::Error
      end
      puts "Managers found: #{managers.size}"
      abort unless managers.size > 0
      puts "Workers found: #{worker_size}"
      printer.worker_size = worker_size
    end

    def printer
      @printer ||= Printer.start(all_specs)
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def reset_manager_threads
      @manager_threads = []
    end

    def resolve_reply(reply)
      DNSSD.resolve!(reply) do |resolved|
        resolved_ip = ip_from_hostname(resolved.target)
        uri = URI::Generic.build :scheme => reply.service_name, :host => resolved_ip, :port => resolved.port
        fetch_manager(uri)
        resolved.service.stop if resolved.service.started?
      end
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def set_up_manager(manager, uri)
      manager.project_name = project_name
      manager.dispatcher_uri = URI::Generic.build :scheme => "specjour", :host => hostname, :port => printer.port
      at_exit { manager.kill_worker_processes }
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
      reset_manager_threads
    end
  end
end
