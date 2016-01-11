module Specjour
  class Printer
    require 'dnssd'

    include Logger
    include SocketHelper

    attr_reader :host, :port, :clients
    attr_accessor :tests_to_run, :test_paths, :example_size, :examples_complete, :profiler, :machines

    COMMANDS = %w(
      done
      greet
      next_test
      ready
      register_tests
      report_test
    )

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
      @loader_pids = []
      self.examples_complete = 0
      set_paths
    end

    def set_paths
      # paths = test_paths.map {|tp| Pathname.new(File.expand_path(tp, Dir.pwd))}
      paths = test_paths.map {|tp| Pathname.new(tp).expand_path}
      if paths.any?
        # @project_path = Pathname.new(find_project_base_dir(paths.first.dirname.to_s))
        @project_path = Pathname.new(find_project_base_dir(paths.first.to_s))
      else
        @project_path = Pathname.new(Dir.pwd)
      end
      if paths.size == 1 and paths.first == project_path
        @test_paths = []
      else
        @test_paths = paths
      end
      # @test_paths = paths.map do |p|
      #   relative = p.relative_path_from(project_path)
      #   if relative != project_path
      #     relative
      #   end
      # end.compact
      abort("#{project_path} doesn't exist") unless project_path.exist?
    end

    def announce
      @output.puts("Searching for listeners...")
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
      # @port = @server_socket.addr[1]
      # fds = [@server_socket]
      # @rp, @wp = IO.pipe
      # @child_socket, @parent_socket = Socket.pair(:UNIX, :DGRAM, 0)
      # catch(:stop) do
      done_reader, @done_writer = IO.pipe
        while running? do
          debug "loop going to select #{running?}"
          result = select([@server_socket, done_reader], [], [])
          reads = result.first
          reads.each do |socket_being_read|
            if socket_being_read == @server_socket
              debug "adding connection"
              client_socket = @server_socket.accept
              # fds << client_socket
              # clients[client_socket] = Connection.wrap(client_socket)
              client_socket = Connection.wrap(client_socket)
              @send_threads << Thread.new(client_socket) { |sock| serve(sock) }
            # elsif socket_being_read.eof?
            #   debug "socket server closing connection"
            #   socket_being_read.close
              # fds.delete(socket_being_read)
              # clients.delete(socket_being_read)
              # disconnecting
            # else
            #   debug "serving"
              # fork do
                # serve(clients[socket_being_read])
              # end
            end
          end
        end
      # end
    ensure
      done_reader.close
      @done_writer.close
      stopping
      if Specjour.interrupted?
        Process.kill("INT", *@loader_pids) rescue TypeError
      end
      exit exit_status
      # fds.each {|c| c.close}
    end

    def exit_status
      if Specjour.interrupted?
        2
      else
        Specjour.configuration.formatter.exit_status
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
          client.close
          disconnecting
          break
        end
        data = client.recv_data
        # @send_threads << Thread.new do
        command = data['command']
        case command
        when "done"
          done(*data["args"])
        when "greet"
          client.send_data greet(*data["args"])
        when "next_test"
          client.send_data next_test(*data["args"])
        when "ready"
          client.send_data ready(*data["args"])
        when "register_tests"
          register_tests(*data["args"])
        when "report_test"
          report_test(*data["args"])
        else
          raise Error.new("COMMAND NOT FOUND: #{command}")
        end
        IO.select([client.socket])
      end
      debug "thread dying"
    end

    def done
      @mutex.synchronize do
        self.examples_complete += 1
      end
    end

    def next_test
      log "test size: #{tests_to_run.size}"
      @mutex.synchronize do
        if tests_to_run.size == example_size
          Specjour.configuration.formatter.start_time = Specjour::Time.now
        end
        tests_to_run.shift
      end
    end

    def ready(info)
      @output.puts "Received connection from #{info["hostname"]}(#{info["worker_size"]})"
      @loader_pids |= [info["loader_pid"]]
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
          # $stderr.puts "EXAMPLES to run #{tests_to_run.join(" ")}"
        end
      end
    end

    def report_test(test)
      @mutex.synchronize do
        Specjour.configuration.formatter.report_test(test)
      end
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

    # def tests=(client, tests)
    #   if tests_to_run.empty?
    #     self.tests_to_run = run_order(tests)
    #     self.example_size = tests_to_run.size
    #   end
    # end

    def rspec_summary=(client, summary)
      rspec_report.add(summary)
    end

    def cucumber_summary=(client, summary)
      cucumber_report.add(summary)
    end

    def add_to_profiler(client, args)
      test, time = *args
      self.profiler[test] = time
    end

    def disconnecting
      # if clients.empty?
      @mutex.synchronize do
        debug "DISCONNECT #{example_size} #{examples_complete}"
        if @running && examples_complete == example_size
          @running = false
          @done_writer.write("DONE")
          debug "server socket closed"
          # @send_threads.each {|t| t.join}
          # throw(:stop)
        end
      end
    end

    def run_order(tests)
      if File.exist?('.specjour/performance')
        ordered_tests = File.readlines('.specjour/performance').map {|l| l.chop.split(':', 2)[1]}
        ordered_tests & tests | tests
      else
        tests
      end
    end

    def rspec_report
      @rspec_report ||= RSpec::FinalReport.new
    end

    def cucumber_report
      @cucumber_report ||= Cucumber::FinalReport.new
    end

    def record_performance
      File.open('.specjour/performance', 'w') do |file|
        ordered_specs = profiler.to_a.sort_by {|a| -a[1].to_f}.map do |test, time|
          file.puts "%6f:%s" % [time, test]
        end
      end
    end

    def stopping
      Specjour.configuration.formatter.print_summary
      @bonjour_service.stop# unless @bonjour_service.stopped?
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
