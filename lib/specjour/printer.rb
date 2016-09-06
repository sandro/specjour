module Specjour
  class Printer
    require 'dnssd'

    include Logger
    include SocketHelper

    attr_reader :host, :port, :clients
    attr_accessor :tests_to_run, :test_paths, :example_size, :examples_complete, :profiler, :machines

    Thread.abort_on_exception = true

    def initialize(options={})
      @options = options
      @host = "0.0.0.0"
      @profiler = {}
      @clients = {}
      @tests_to_run = []
      @test_paths = options[:test_paths]
      @example_size = 0
      @machines = []
      @send_threads = []
      @bonjour_service = nil
      @mutex = Mutex.new
      @running = false
      @output = options[:output] || $stdout
      @loader_clients = []
      self.examples_complete = 0
      set_paths
      Specjour.configuration.printer_port ||= SocketHelper.new_uri.port
    end

    def set_paths
      paths = test_paths.map {|tp| Pathname.new(tp).expand_path}
      if paths.any?
        @project_path = Pathname.new(find_project_base_dir(paths.first.to_s))
      else
        @project_path = Pathname.new(Dir.pwd)
      end
      if paths.size == 1 and paths.first == project_path
        @test_paths = []
      else
        @test_paths = paths
      end
      @test_paths = @test_paths.map do |path|
        test_path = path.relative_path_from(project_path)
        abort("Test path #{test_path} doesn't exist") unless test_path.exist?
        test_path
      end
      if !project_path.exist?
        abort("Project path #{project_path} doesn't exist")
      end
    end

    def announce
      @output.puts("Looking for listeners...")
      text = DNSSD::TextRecord.new
      text['version'] = Specjour::VERSION
      text['project_alias'] = Specjour.configuration.project_aliases.first
      @bonjour_service = DNSSD.register "#{hostname}".tr(".","-"), "_specjour._tcp", domain=nil, Specjour.configuration.printer_port, text
    end

    def start_rsync
      rsync_daemon.start
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path.to_s, project_name, Specjour.configuration.rsync_port)
    end

    def process_io

    end

    def running?
      @mutex.synchronize do
        @running
      end
    end

    def start
      @running = true
      @server_socket ||= TCPServer.new(@host, Specjour.configuration.printer_port)
      done_reader, @done_writer = IO.pipe
      while running? do
        debug "loop going to select #{running?}"
        result = select([@server_socket, done_reader], [], [])
        reads = result.first
        reads.each do |socket_being_read|
          if socket_being_read == @server_socket
            debug "adding connection"
            client_socket = @server_socket.accept
            client_socket = Connection.wrap(client_socket)
            @send_threads << Thread.new(client_socket) { |sock| serve(sock) }
          end
        end
      end
      done_reader.close
      @done_writer.close
    ensure
      if Specjour.interrupted?
        @loader_clients.each do |client|
          client.socket.puts("INT")
        end
      end
      @server_socket.close
      stopping
      exit exit_status
    end

    def exit_status
      if Specjour.interrupted?
        2
      else
        statuses = Specjour.plugin_manager.send_task(:exit_status, Specjour.configuration.formatter)
        plugin_status = statuses.detect {|s| !s.nil?}
        plugin_status.nil? ? Specjour.configuration.formatter.exit_status : plugin_status
      end
    end

    def uri
      @uri ||= URI::Generic.build host: host, port: port
    end

    def project_name
      options[:project_alias] || project_path.basename.to_s
    end

    def project_path
      @project_path
    end

    protected

    def serve(client)
      debug "serving #{client.inspect}"
      loop do
        if client.eof?
          debug "client eof"
          client.disconnect
          disconnecting
          break
        end
        data = client.recv_data
        command = data['command']
        case command
        when "add_to_profiler"
          add_to_profiler(*data["args"])
        when "done"
          done(*data["args"])
        when "greet"
          client.send_data greet(*data["args"])
        when "next_test"
          client.send_data next_test(*data["args"])
        when "ready"
          @loader_clients |= [client]
          client.send_data ready(*data["args"])
        when "register_tests"
          register_tests(*data["args"])
        when "report_test"
          report_test(*data["args"])
        when "error"
          unexpected_error(*data["args"])
        else
          raise Error.new("COMMAND NOT FOUND: #{command}")
        end
        IO.select([client.socket])
      end
    end

    def done
      @mutex.synchronize do
        self.examples_complete += 1
      end
    end

    def next_test
      @mutex.synchronize do
        log "test size: #{tests_to_run.size}"
        if tests_to_run.size == example_size
          Specjour.configuration.formatter.start_time = Specjour::Time.now
        end
        tests_to_run.shift
      end
    end

    def ready(info)
      @output.puts "Found #{info["hostname"]}(#{info["worker_size"]})"
      {
        project_name: project_name,
        project_path: project_path.to_s,
        test_paths: test_paths
      }
    end

    def greet(message)
      { received: message }
    end

    def register_tests(tests)
      @mutex.synchronize do
        if example_size == 0
          self.tests_to_run = run_order(tests)
          self.example_size = tests_to_run.size
        end
      end
    end

    def report_test(test)
      @mutex.synchronize do
        Specjour.configuration.formatter.report_test(test)
      end
    end

    def unexpected_error(message)
      @output.puts message
    end

    def find_project_base_dir(directory)
      dirs = Dir["#{directory}/Rakefile"]
      if dirs.any?
        File.dirname dirs.first
      else
        find_project_base_dir(File.dirname(directory))
      end
    end

    def options
      {}
    end

    def machines=(client, machines)
      @machines = machines
    end

    def rspec_summary=(client, summary)
      rspec_report.add(summary)
    end

    def cucumber_summary=(client, summary)
      cucumber_report.add(summary)
    end

    def add_to_profiler(test, time, host)
      self.profiler[test] = [time, host]
    end

    def disconnecting
      @mutex.synchronize do
        debug "DISCONNECT #{example_size} #{examples_complete}"
        if @running && examples_complete == example_size
          @running = false
          @done_writer.write("DONE")
        end
      end
    end

    def run_order(tests)
      if File.exist?('.specjour/performance')
        ordered_tests = File.readlines('.specjour/performance').map {|l| l.chop.split(':')[1]}
        ordered_tests & tests | tests
      else
        tests.sort
      end
    end

    def rspec_report
      @rspec_report ||= RSpec::FinalReport.new
    end

    def cucumber_report
      @cucumber_report ||= Cucumber::FinalReport.new
    end

    # "test.rb" => [1.12, "host.local[2]"]
    def record_performance
      File.open('.specjour/performance', 'w') do |file|
        ordered_specs = profiler.to_a.sort_by {|test, data| -data[0].to_f}.map do |test, data|
          file.puts "%6f:%s:%s" % [data[0], test, data[1]]
        end
      end
    end

    def stopping
      Specjour.configuration.formatter.set_end_time!
      @bonjour_service.stop# unless @bonjour_service.stopped?

      Specjour.plugin_manager.send_task(:before_print_summary, Specjour.configuration.formatter)
      Specjour.configuration.formatter.print_summary
      Specjour.plugin_manager.send_task(:after_print_summary, Specjour.configuration.formatter)

      unless Specjour.interrupted?
        record_performance
        print_missing_tests if missing_tests?
      end
    end

    def missing_tests?
      examples_complete != example_size && tests_to_run.any?
    end

    def print_missing_tests
      @output.puts "*" * 60
      @output.puts "Oops! The following tests were not run:"
      @output.puts "*" * 60
      @output.puts tests_to_run
      @output.puts "*" * 60
    end

  end
end
