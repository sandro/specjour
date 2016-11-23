module Specjour
  class Listener
    require 'dnssd'
    Thread.abort_on_exception = true

    LOCK_FILE = "listener.lock"

    include Logger
    include SocketHelper

    attr_accessor :options, :printer

    def self.ensure_started
      listener = new
      unless listener.started?
        listener_pid = fork do
          listener.daemonize
          listener.start
        end
        Process.detach(listener_pid)
      end
      listener
    end

    def initialize(options={})
      self.options = options
    end

    def available_for?(project_name)
      if Specjour.configuration.project_aliases.any? || !project_name.empty?
        Specjour.configuration.project_aliases.include? project_name
      else
        true
      end
    end

    def config_directory
      return @config_directory if @config_directory
      @config_directory = File.join(Dir.tmpdir, "specjour")
      FileUtils.mkdir_p @config_directory
      @config_directory
    end

    def daemonize
      Process.daemon
    end

    def add_printer(params)
      log "Listener adding printer #{params}"
      self.printer = params
      Specjour.configuration.printer_uri = params[:uri]
      Specjour.configuration.remote_job = remote_ip?(params[:ip])
    end

    def remove_printer
      self.printer = nil
      Specjour.configuration.printer_uri = nil
      Specjour.configuration.remote_job = nil
    end

    def fork_loader
      Specjour.plugin_manager.send_task(:before_loader_fork)
      fork do
        loader = Loader.new({task: "run_tests"})
        Specjour.plugin_manager.send_task(:after_loader_fork)
        loader.start
      end
    end

    def gather
      @dnssd_service = DNSSD.browse!('_specjour._tcp') do |reply|
        log ['reply', reply.name, reply.service_name, reply.domain,reply.flags, reply.interface]
        if reply.flags.add?
          DNSSD.resolve!(reply.name, reply.type, reply.domain, flags=0, reply.interface) do |resolved|
            log "Bonjour discovered #{resolved.target} #{resolved.text_record.inspect}"
            if resolved.text_record && resolved.text_record['version'] == Specjour::VERSION
              if available_for?(resolved.text_record['project_alias'].to_s)
                resolved_ip = ip_from_hostname(resolved.target)
                uri = URI::Generic.build :host => resolved_ip, :port => resolved.port
                add_printer(name: resolved.name, uri: uri, ip: resolved_ip)
              else
                $stderr.puts "Found #{resolved.target} but not listening to project alias: #{resolved.text_record['project_alias']}. Skipping..."
              end
            else
              $stderr.puts "Found #{resolved.target} but its version doesn't match v#{Specjour::VERSION}. Skipping..."
            end
            break
          end
          break if printer
        else
          log "REMOVING #{reply.name} #{reply}"
          remove_printer
        end
      end
    end

    def pid
      if File.exist?(pid_file) && !File.directory?(pid_file)
        File.read(pid_file).strip.to_i
      end
    end

    def pid_file
      @pid_file ||= File.join(config_directory, "#{Specjour.configuration.project_aliases.join("-")}.pid")
    end

    def lock_file
      @lock_file ||= File.join(config_directory, LOCK_FILE)
    end

    # only allow one listener to execute at a time
    def listener_lock(&block)
      exception = nil
      File.open(lock_file, "w") do |file|
        begin
          debug "Acquiring listener lock"
          file.flock File::LOCK_EX
          debug "Listener lock acquired"
          block.call
        rescue => exception
          file.flock File::LOCK_UN
        end
      end
      raise exception if exception
    end

    def program_name
      name = "specjour listen"
      if Specjour.configuration.project_aliases.any?
        name += " -a #{Specjour.configuration.project_aliases.join(",")}"
      end
      name
    end

    def start
      $PROGRAM_NAME = program_name
      log "Listener starting"
      write_pid
      loop do
        log "listening..."
        gather
        listener_lock do
          @loader_pid = fork_loader
          Process.waitall
          remove_printer
          sleep 3 # let bonjour services stop
        end
      end
    rescue StandardError, ScriptError => e
      $stderr.puts "RESCUED #{e.message}"
      $stderr.puts e.backtrace
      connection.error(e)
    ensure
      remove_pid
      remove_connection
      log "Shutting down listener"
    end

    def started?
      !pid.nil?
    end

    def stop
      Process.kill("TERM", pid) rescue TypeError
    ensure
      remove_pid
    end

    def write_pid
      File.open(pid_file, 'w') do |f|
        f.write Process.pid
      end
    end

    def remove_pid
      File.unlink(pid_file) if File.exist?(pid_file) && pid == Process.pid
    end
  end
end
