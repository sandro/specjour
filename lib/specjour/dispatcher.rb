module Specjour
  class Dispatcher
    require 'dnssd'
    Thread.abort_on_exception = true
    include SocketHelper

    attr_reader :project_alias, :managers, :manager_threads, :hosts, :options, :drb_connection_errors, :test_paths, :rsync_port
    attr_accessor :worker_size, :project_path

    def initialize(options = {})
      Specjour.load_custom_hooks
      @options = options
      @project_path = options[:project_path]
      @test_paths = options[:test_paths]
      @worker_size = 0
      @managers = []
      @drb_connection_errors = Hash.new(0)
      @rsync_port = options[:rsync_port]
      @manager_threads = []
    end

    def start
      abort("#{project_path} doesn't exist") unless File.directory?(project_path)
      gather_managers
      rsync_daemon.start
      dispatch_work
      if dispatching_tests?
        printer.start
      else
        wait_on_managers
      end
      exit printer.exit_status
    end

    protected

    def add_manager(manager)
      set_up_manager(manager)
      managers << manager
      self.worker_size += manager.worker_size
    end

    def command_managers(&block)
      managers.each do |manager|
        manager_threads << Thread.new(manager, &block)
      end
    end

    def dispatcher_uri
      @dispatcher_uri ||= URI::Generic.build :scheme => "specjour", :host => local_ip, :port => printer.port
    end

    def dispatch_work
      puts "Workers found: #{worker_size}"
      managers.each do |manager|
        puts "#{manager.hostname} (#{manager.worker_size})"
      end
      command_managers { |m| m.dispatch rescue DRb::DRbConnError }
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
      sleep(0.1) && retry if drb_connection_errors[uri] < 5
    end

    def fork_local_manager
      puts "No listeners found on this machine, starting one..."
      manager_options = {:worker_size => options[:worker_size], :registered_projects => [project_alias], :rsync_port => rsync_port}
      manager = Manager.start_quietly manager_options
      Process.detach manager.pid
      fetch_manager(manager.drb_uri)
      at_exit do
        unless Specjour.interrupted?
          Process.kill('TERM', manager.pid) rescue Errno::ESRCH
        end
      end
    end

    def gather_managers
      puts "Looking for listeners..."
      gather_remote_managers
      fork_local_manager if local_manager_needed?
      abort "No listeners found" if managers.size.zero?
    end

    def gather_remote_managers
      replies = []
      Timeout.timeout(1) do
        DNSSD.browse!('_druby._tcp') do |reply|
          replies << reply if reply.flags.add?
          break unless reply.flags.more_coming?
        end
        raise Timeout::Error
      end
    rescue Timeout::Error
      replies.each {|r| resolve_reply(r)}
    end

    def local_manager_needed?
      options[:worker_size] > 0 && no_local_managers?
    end

    def no_local_managers?
      managers.none? {|m| m.local_ip == local_ip}
    end

    def printer
      @printer ||= Printer.new
    end

    def project_alias
      @project_alias ||= options[:project_alias] || project_name
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def resolve_reply(reply)
      Timeout.timeout(1) do
        DNSSD.resolve!(reply.name, reply.type, reply.domain, flags=0, reply.interface) do |resolved|
          Specjour.logger.debug "Bonjour discovered #{resolved.target}"
          if resolved.text_record && resolved.text_record['version'] == Specjour::VERSION
            resolved_ip = ip_from_hostname(resolved.target)
            uri = URI::Generic.build :scheme => reply.service_name, :host => resolved_ip, :port => resolved.port
            fetch_manager(uri)
          else
            puts "Found #{resolved.target} but its version doesn't match v#{Specjour::VERSION}. Skipping..."
          end
          break unless resolved.flags.more_coming?
        end
      end
    rescue Timeout::Error
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name, rsync_port)
    end

    def set_up_manager(manager)
      manager.project_name = project_name
      manager.dispatcher_uri = dispatcher_uri
      manager.test_paths = test_paths
      manager.worker_task = worker_task
      at_exit do
        begin
          manager.interrupted = Specjour.interrupted?
        rescue DRb::DRbConnError
        end
      end
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
    end

    def worker_task
      options[:worker_task] || 'run_tests'
    end
  end
end
