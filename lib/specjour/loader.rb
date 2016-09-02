module Specjour
  require 'specjour/worker'
  class Loader
    include Logger
    include SocketHelper

    attr_reader \
      :options,
      :printer_uri,
      :quiet,
      :task,
      :worker_pids

    def initialize(options = {})
      @options = options
      @printer_uri = options[:printer_uri]
      @task = options[:task]
      @quiet = options[:quiet]
      @worker_pids = []
    end

    def start
      Process.setsid
      $PROGRAM_NAME = "specjour loader"
      # Specjour.trap_interrupt
      # Process.setsid
      set_up
      sync
      # Specjour.load_custom_hooks
      Specjour.plugin_manager.send_task(:load_application)
      Specjour.plugin_manager.send_task(:register_tests_with_printer)
      fork_workers
      wait_srv
      # select [connection.socket] # wait for server to disconnect
      # Process.waitall
    rescue StandardError, ScriptError => e
      $stderr.puts "RESCUED #{e.class} '#{e.message}'"
      $stderr.puts e.backtrace
      $stderr.puts "\n\n"
    ensure
      Process.waitall
      remove_connection
      $stderr.puts("loader ENSURE")
      log "Loader killing group #{Process.getsid}"
      # Process.kill("KILL", -Process.getsid)
    end

    def fork_workers
      Specjour.plugin_manager.send_task(:before_worker_fork)
      (1..Specjour.configuration.worker_size).each do |index|
        worker_pids << fork do
          $PROGRAM_NAME = "specjour worker"
          worker = Worker.new(
            :number => index,
            :quiet => quiet
          )
          Specjour.plugin_manager.send_task(:after_worker_fork)
          worker.send(task)
        end
      end
    end

    def wait_srv
      select [connection.socket]
      if connection.socket.eof?
        $stderr.puts("server eof")
      else
        val = connection.socket.gets
        $stderr.puts("LOADER GOT #{val}")
        Process.kill("INT", -Process.getsid)
      end
    end

    def set_up
      data = connection.ready({hostname: hostname, worker_size: Specjour.configuration.worker_size, loader_pid: Process.pid})
      Specjour.configuration.project_name = data["project_name"]
      Specjour.configuration.test_paths = data["test_paths"]
      Specjour.configuration.project_path = File.expand_path(Specjour.configuration.project_name, Specjour.configuration.tmp_path)
      # Thread.new(connection) do |conn|
      # end
    end

    def sync
      cmd "rsync #{Specjour.configuration.rsync_options} --port=#{Specjour.configuration.rsync_port} #{connection.host}::#{Specjour.configuration.project_name} #{Specjour.configuration.project_path}"
      Dir.chdir Specjour.configuration.project_path
    end

    def cmd(command)
      Specjour.benchmark(command) do
        system *command.split
      end
    end
  end
end
