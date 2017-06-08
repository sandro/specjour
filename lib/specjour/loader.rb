module Specjour
  require 'specjour/worker'
  class Loader
    include Logger
    include SocketHelper

    attr_reader \
      :options,
      :quiet,
      :task,
      :worker_pids

    def initialize(options = {})
      @options = options
      @task = options[:task]
      @quiet = options[:quiet]
      @worker_pids = []
    end

    def start
      Process.setsid
      $PROGRAM_NAME = "specjour loader"
      debug "Loader pid: #{Process.pid} ppid: #{Process.ppid}"
      set_up
      sync
      Specjour.plugin_manager.send_task(:load_application)
      Specjour.plugin_manager.send_task(:register_tests_with_printer)
      fork_workers
      wait_srv
    rescue StandardError, ScriptError => e
      $stderr.puts "RESCUED #{e.class} '#{e.message}'"
      $stderr.puts e.backtrace
      $stderr.puts "\n\n"
      connection.error(e)
      remove_connection
      kill_parent
    ensure
      remove_connection
    end

    def fork_workers
      Specjour.plugin_manager.send_task(:before_worker_fork)
      (1..Specjour.configuration.worker_size).each do |index|
        worker_pids << fork do
          remove_connection
          Specjour.plugin_manager.send_task(:remove_connection)
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
      if !connection.socket.eof?
        signal = connection.get_server_done
        case signal
        when "INT"
          kill_session
        end
      end
    end

    def kill_session
      debug "Sending INT to session -#{Process.getsid}"
      Process.kill("INT", -Process.getsid) rescue nil
    end

    # shut down the parent before it restarts this loader in a loop
    def kill_parent
      debug "Sending INT to parent -#{Process.ppid}"
      Process.kill("INT", Process.ppid) rescue nil
    end

    def set_up
      data = connection.ready({hostname: hostname, worker_size: Specjour.configuration.worker_size})
      Specjour.configuration.project_name = data[:project_name]
      Specjour.configuration.test_paths = data[:test_paths]
      Specjour.configuration.project_path = File.expand_path(Specjour.configuration.project_name, Specjour.configuration.tmp_path)
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
