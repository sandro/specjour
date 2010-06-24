module Specjour
  class Dispatcher
    require 'dnssd'
    Thread.abort_on_exception = true
    include SocketHelper

    class << self
      attr_accessor :interrupted
      alias interrupted? interrupted

      Signal.trap('INT') { Dispatcher.interrupted = true; exit 1 }
    end

    attr_reader :project_alias, :managers, :manager_threads, :hosts, :options, :all_tests
    attr_accessor :worker_size, :discovery_attempts, :project_path

    def initialize(options = {})
      @options = options
      @project_path = File.expand_path options[:project_path]
      @worker_size = 0
      @managers = []
      @discovery_attempts = 0
      find_tests
      clear_manager_threads
    end

    def start
      start_manager if options[:worker_size] > 0
      rsync_daemon.start
      gather_managers
      dispatch_work
      printer.join
      exit printer.exit_status
    end

    protected

    def find_tests
      if project_path.match(/(.+)\/((spec|features)(?:\/\w+)*)$/)
        self.project_path = $1
        @all_tests = $3 == 'spec' ? all_specs($2) : all_features($2)
      else
        @all_tests = Array(all_specs) | Array(all_features)
      end
    end

    def all_specs(tests_path = 'spec')
      Dir.chdir(project_path) do
        Dir[File.join(tests_path, "**/*_spec.rb")].sort
      end if File.exists? File.join(project_path, tests_path)
    end

    def all_features(tests_path = 'features')
      Dir.chdir(project_path) do
        Dir[File.join(tests_path, "**/*.feature")].sort
      end if File.exists? File.join(project_path, tests_path)
    end

    def command_managers(async = false, &block)
      managers.each do |manager|
        manager_threads << Thread.new(manager, &block)
      end
      wait_on_managers unless async
    end

    def dispatch_work
      puts "Managers found: #{managers.size}"
      puts "Workers found: #{worker_size}"
      printer.worker_size = worker_size
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
      puts "Looking for managers..."
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
      if managers.size < 1 && discovery_attempts < 10
        sleep 1
        self.discovery_attempts += 1
        gather_managers
      elsif managers.size == 0 && discovery_attempts == 10
        abort "No managers found"
      end
    end

    def printer
      @printer ||= Printer.start(all_tests)
    end

    def project_alias
      @project_alias ||= options[:project_alias] || project_name
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def clear_manager_threads
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
      at_exit { manager.kill_worker_processes rescue DRb::DRbConnError }
    end

    def start_manager
      process = IO.popen %(specjour listen --projects #{project_name} --workers #{options[:worker_size]})
      Process.detach process.pid
      at_exit { Process.kill('TERM', process.pid) rescue Errno::ESRCH }
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
      clear_manager_threads
    end
  end
end
