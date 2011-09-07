module Specjour
  class Dispatcher
    require 'dnssd'
    Thread.abort_on_exception = true
    include SocketHelper

    attr_reader :project_alias, :managers, :manager_threads, :hosts, :options, :all_tests, :drb_connection_errors
    attr_accessor :worker_size, :project_path

    def initialize(options = {})
      Specjour.load_custom_hooks
      @options = options
      @project_path = File.expand_path options[:project_path]
      @worker_size = 0
      @managers = []
      @drb_connection_errors = Hash.new(0)
      find_tests
      clear_manager_threads
    end

    def start
      abort("#{project_path} doesn't exist") unless File.directory?(project_path)
      gather_managers
      rsync_daemon.start
      dispatch_work
      printer.start if dispatching_tests?
      wait_on_managers
      exit printer.exit_status
    end

    protected

    def find_tests
      if project_path.match(/(.+)\/((spec|features)(?:\/\w+)*)$/)
        self.project_path = $1
        @all_tests = $3 == 'spec' ? all_specs($2) : all_features($2)
      else
        @all_tests = all_specs | all_features
      end
    end

    def all_specs(tests_path = 'spec')
      Dir[File.join(".", tests_path, "**/*_spec.rb")].sort
    end

    def all_features(tests_path = 'features')
      Dir[File.join(".", tests_path, "**/*.feature")].sort
    end

    def add_manager(manager)
      set_up_manager(manager)
      managers << manager
      self.worker_size += manager.worker_size
    end

    def command_managers(async = false, &block)
      managers.each do |manager|
        manager_threads << Thread.new(manager, &block)
      end
      wait_on_managers unless async
    end

    def dispatcher_uri
      @dispatcher_uri ||= URI::Generic.build :scheme => "specjour", :host => hostname, :port => printer.port
    end

    def dispatch_work
      puts "Workers found: #{worker_size}"
      managers.each do |manager|
        puts "#{manager.hostname} (#{manager.worker_size})"
      end
      printer.worker_size = worker_size
      command_managers(true) { |m| m.dispatch rescue DRb::DRbConnError }
    end

    def dispatching_tests?
      worker_task == 'run_tests'
    end

    def fetch_manager(uri)
      manager = DRbObject.new_with_uri(uri.to_s)
      if !managers.include?(manager) && manager.available_for?(project_alias)
        add_manager(manager)
      end
    rescue DRb::DRbConnError => e
      drb_connection_errors[uri] += 1
      Specjour.logger.debug "#{e.message}: couldn't connect to manager at #{uri}"
      retry if drb_connection_errors[uri] < 5
    end

    def fork_local_manager
      puts "No listeners found on this machine, starting one..."
      manager_options = {:worker_size => options[:worker_size], :registered_projects => [project_alias]}
      manager = Manager.start_quietly manager_options
      fetch_manager(manager.drb_uri)
      at_exit do
        unless Specjour.interrupted?
          Process.kill('TERM', manager.pid) rescue Errno::ESRCH
        end
      end
    end

    def gather_managers
      puts "Looking for managers..."
      gather_remote_managers
      fork_local_manager if local_manager_needed?
      abort "No managers found" if managers.size.zero?
    end

    def gather_remote_managers
      browser = DNSSD::Service.new
      Timeout.timeout(3) do
        browser.browse '_druby._tcp' do |reply|
          if reply.flags.add?
            resolve_reply(reply)
          end
          browser.stop unless reply.flags.more_coming?
        end
      end
      rescue Timeout::Error
    end

    def local_manager_needed?
      options[:worker_size] > 0 && no_local_managers?
    end

    def no_local_managers?
      managers.none? {|m| m.hostname == hostname}
    end

    def printer
      @printer ||= Printer.new(all_tests)
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
        Specjour.logger.debug "Bonjour discovered #{resolved.target}"
        resolved_ip = ip_from_hostname(resolved.target)
        uri = URI::Generic.build :scheme => reply.service_name, :host => resolved_ip, :port => resolved.port
        fetch_manager(uri)
        resolved.service.stop if resolved.service.started?
      end
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def set_up_manager(manager)
      manager.project_name = project_name
      manager.dispatcher_uri = dispatcher_uri
      manager.preload_spec = all_tests.detect {|f| f =~ /_spec\.rb$/}
      manager.preload_feature = all_tests.detect {|f| f =~ /\.feature$/}
      manager.worker_task = worker_task
      at_exit do
        begin
          manager.interrupted = Specjour.interrupted?
          manager.kill_worker_processes
        rescue DRb::DRbConnError
        end
      end
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
      clear_manager_threads
    end

    def worker_task
      options[:worker_task] || 'run_tests'
    end
  end
end
