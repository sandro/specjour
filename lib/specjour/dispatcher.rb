module Specjour
  class Dispatcher
    require 'dnssd'
    Thread.abort_on_exception = true

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
      sync_managers
      dispatch_work
      printer.join
    end

    protected

    def all_specs
      @all_specs ||= Dir.chdir(project_path) do
        Dir["spec/**/**/*_spec.rb"].partition {|f| f =~ /integration/}.flatten
      end
    end

    def dispatch_work
      distributable_specs = all_specs.among(worker_size)
      last_index = 0
      managers.each_with_index do |manager, index|
        manager.specs_to_run = Array.new(manager.worker_size) do |i|
          distributable_specs[last_index + i]
        end
        last_index += manager.worker_size
        manager_threads << Thread.new(manager) {|m| m.dispatch}
      end
    end

    def drb_start
      DRb.start_service nil, self
      at_exit { puts 'shutting down DRb client'; DRb.stop_service }
    end

    def fetch_manager(uri)
      manager = DRbObject.new_with_uri(uri.to_s)
      unless managers.include?(manager)
        set_up_manager(manager, uri)
        managers << manager
        self.worker_size += manager.worker_size
      end
    end

    def gather_managers
      puts "Waiting for managers"
      Signal.trap('INT') { exit }
      browser = DNSSD::Service.new
      browser.browse '_druby._tcp' do |reply|
        if reply.flags.add?
          resolve_reply(reply)
        end
        browser.stop unless reply.flags.more_coming?
      end
      puts "Managers found: #{managers.size}"
      printer.worker_size = worker_size
    end

    def printer
      @printer ||= Printer.new.start
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def reset_manager_threads
      @manager_threads = []
    end

    def resolve_reply(reply)
      DNSSD.resolve!(reply) do |resolved|
        uri = URI::Generic.build :scheme => reply.service_name, :host => resolved.target, :port => resolved.port
        fetch_manager(uri)
        resolved.service.stop if resolved.service.started?
      end
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def set_up_manager(manager, uri)
      manager.project_name = project_name
      manager.dispatcher_uri = URI::Generic.build :scheme => "specjour", :host => printer.hostname, :port => printer.port
    end

    def sync_managers
      managers.each do |manager|
        manager_threads << Thread.new(manager) { |manager| manager.sync }
      end
      wait_on_managers
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
      reset_manager_threads
    end
  end
end
