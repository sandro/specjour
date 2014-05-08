module Specjour
  class Listener
    require 'dnssd'
    Thread.abort_on_exception = true

    PID_FILE_NAME = "listener.pid"

    include Logger
    include SocketHelper

    attr_accessor :options, :printer

    def initialize(options={})
      self.options = options
    end

    def available_for?(project_name)
      registered_projects ? registered_projects.include?(project_name) : false
    end

    def registered_projects
      []
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
      Specjour.configuration.options[:printer_uri] = params[:uri]
    end

    def remove_printer
      self.printer = nil
      Specjour.configuration.options[:printer_uri] = nil
    end

    def fork_loader
      Specjour.plugin_manager.send_task(:before_loader_fork)
      fork do
        Loader.new(printer_uri: connection.uri, task: "run_tests").start
      end
    end

    def gather
      DNSSD.browse!('_specjour._tcp') do |reply|
        p ['reply', reply.name, reply.service_name, reply.domain,reply.flags]
        if reply.flags.add?
          DNSSD.resolve!(reply.name, reply.type, reply.domain, flags=0, reply.interface) do |resolved|
            log "Bonjour discovered #{resolved.target}"
            if resolved.text_record && resolved.text_record['version'] == Specjour::VERSION
              resolved_ip = ip_from_hostname(resolved.target)
              uri = URI::Generic.build :host => resolved_ip, :port => resolved.port
              add_printer(name: resolved.name, uri: uri)
              break
            else
              $stderr.puts "Found #{resolved.target} but its version doesn't match v#{Specjour::VERSION}. Skipping..."
            end
          end
          break
        # else
        #   remove_printer
        end
      end
    end

    def pid
      if File.exists?(pid_file)
        File.read(pid_file).strip.to_i
      end
    end

    def pid_file
      File.join(config_directory, PID_FILE_NAME)
    end

    def start
      unless started?
        log "Listener starting"
        write_pid
        gather
        @loader_pid = fork_loader
        select [connection.socket] # wait until server disconnects
      end
    ensure
      shutdown
    end

    def started?
      !pid.nil?
    end

    def shutdown
      log "Shutting down listener, and loader"
      connection.disconnect
      remove_printer
    rescue Exception => e
      $stderr.puts "RESCUED #{e.message}"
      $stderr.puts e.backtrace
      Process.kill("TERM", @loader_pid) rescue TypeError
    ensure
      File.unlink pid_file
    end

    def write_pid
      File.open(pid_file, 'w') do |f|
        f.write Process.pid
      end
    end
  end
end
