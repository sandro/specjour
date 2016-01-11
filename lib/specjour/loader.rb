module Specjour
  require 'specjour/worker'
  class Loader
    include Logger
    include SocketHelper

    attr_reader \
      :options,
      :printer_uri,
      :project_path,
      :quiet,
      :task,
      :worker_pids,
      :worker_size

    def initialize(options = {})
      @options = options
      @printer_uri = options[:printer_uri]
      @worker_size = options[:worker_size]
      @task = options[:task]
      @quiet = options[:quiet]
      @worker_pids = []
    end

    def start
      $PROGRAM_NAME = "specjour loader"
      Process.setsid
      set_up
      Specjour.benchmark("RSYNC") do
        sync
      end
      # Specjour.load_custom_hooks
      Specjour.plugin_manager.send_task(:load_application)
      Specjour.plugin_manager.send_task(:register_tests_with_printer)
      fork_workers
      # select [connection.socket] # wait for server to disconnect
      Process.waitall
    rescue StandardError, ScriptError => e
      $stderr.puts "RESCUED #{e.class} '#{e.message}'"
      $stderr.puts e.backtrace
      $stderr.puts "\n\n"
    ensure
      log "Loader killing group #{Process.getpgrp}"
      Process.kill("KILL", -Process.getpgrp)
      Process.waitall
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

    def load_application
      puts caller
      Specjour.configuration.load_application
    end

    def set_up
      data = connection.ready({hostname: hostname, worker_size: Specjour.configuration.worker_size, loader_pid: Process.pid})
      Specjour.configuration.project_name = data["project_name"]
      Specjour.configuration.project_path = data["project_path"]
      Specjour.configuration.test_paths = data["test_paths"]
    end

    def project_path
      File.expand_path(Specjour.configuration.project_name, '/tmp')
    end

    def sync
      cmd "rsync #{Specjour.configuration.rsync_options} --port=#{Specjour.configuration.rsync_port} #{connection.host}::#{Specjour.configuration.project_name} #{project_path}"
      Dir.chdir project_path
    end

    def cmd(command)
      Specjour.benchmark(command) do
        system *command.split
      end
    end

    # def kill_worker_processes
    #   Process.kill("QUIT", *worker_pids) rescue Errno::ESRCH
    # end

    # def start
    #   load_app
    #   Configuration.after_load.call
    #   (1..worker_size).each do |index|
    #     worker_pids << fork do
    #       Worker.new(
    #         :number => index,
    #         :printer_uri => printer_uri,
    #         :quiet => quiet
    #       ).send(task)
    #     end
    #   end
    #   Process.waitall
    # ensure
    #   kill_worker_processes
    # end

    def feature_files
      if test_paths.empty?
        Dir["#{project_path}/features/**/*_feature.rb"]
      else
        test_paths.map do |test_path|
          if test_path =~ /_feature\.rb$/
            Dir["#{project_path}/#{test_path}"]
          end
        end.flatten.compact
      end
    #   @feature_files ||= file_collector(feature_paths) do |path|
    #     if path == project_path
    #       Dir["#{path}/features/**/*.feature"]
    #     else
    #       Dir["#{path}/**/*.feature"]
    #     end
    #   end
    end

    # protected

    # def spec_paths
    #   @spec_paths ||= test_paths.select {|p| p =~ /spec.*$/}
    # end

    # def feature_paths
    #   @feature_paths ||= test_paths.select {|p| p =~ /features.*$/}
    # end

    # def file_collector(paths, &globber)
    #   if spec_paths.empty? && feature_paths.empty?
    #     globber[project_path]
    #   else
    #     paths.map do |path|
    #       path = File.expand_path(path, project_path)
    #       if File.directory?(path)
    #         globber[path]
    #       else
    #         path
    #       end
    #     end.flatten.uniq
    #   end
    # end

    # def load_app
    #   RSpec::Preloader.load spec_files if spec_files.any?

    #   $stderr.puts ['feature files', feature_files].inspect
    #   Cucumber::Preloader.load(feature_files, connection) if feature_files.any?
    #   register_tests_with_printer
    # end

    def cucumber_scenarios
      if feature_files.any?
        scenarios
      else
        []
      end
    end

    # def scenarios
    #   Cucumber.runtime.send(:features).map do |feature|
    #     feature.feature_elements.map do |scenario|
    #       "#{feature.file}:#{scenario.instance_variable_get(:@line)}"
    #     end
    #   end.flatten
    # end

    # def connection
    #   @connection ||= begin
    #     at_exit { connection.disconnect }
    #     Connection.new URI.parse(printer_uri)
    #   end
    # end

  end
end
