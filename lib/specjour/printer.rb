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
      text = DNSSD::TextRecord.new
      text['version'] = Specjour::VERSION
      projects = []
      @bonjour_service = DNSSD.register "#{projects.join(",")}@#{hostname}".tr(".","-"), "_specjour._tcp", domain=nil, Specjour.configuration.printer_port, text
    end

    def start_rsync
      rsync_daemon.start
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path.to_s, project_name, Specjour.configuration.rsync_port)
    end

    def start
      @server_socket ||= TCPServer.new(@host, Specjour.configuration.printer_port)
      # @port = @server_socket.addr[1]
      fds = [@server_socket]
      catch(:stop) do
        while true do
          reads = select(fds).first
          reads.each do |socket_being_read|
            if socket_being_read == @server_socket
              debug "adding connection"
              client_socket = @server_socket.accept
              fds << client_socket
              clients[client_socket] = Connection.wrap(client_socket)
            elsif socket_being_read.eof?
              debug "closing connection"
              socket_being_read.close
              fds.delete(socket_being_read)
              clients.delete(socket_being_read)
              disconnecting
            else
              debug "serving"
              # @send_threads << Thread.new { serve(clients[socket_being_read]) }
              serve(clients[socket_being_read])
            end
          end
        end
      end
    ensure
      stopping
      fds.each {|c| c.close}
    end

    def exit_status
      reporters.all? {|r| r.exit_status == true} && !reporters.empty?
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
      data = client.recv_data
      @mutex.synchronize { @send_threads.reject! {|t| !t.alive?} }
      # @send_threads << Thread.new do
      command = data['command']
      if COMMANDS.include?(command)
        if command == "report_test"
          client.send_data true
          # Thread.new do
            send(data['command'], *data['args'])
          # end
        else
          # @send_threads << Thread.new do
          # fork do
            log "have command #{command}"
            client.send_data send(command, *data['args'])
            $stderr.puts "done in fork"
          # end
          # end
        end
      else
        raise Error.new("COMMAND NOT FOUND: #{data['command']}")
      end
      # end
      # case data
      # when String
      #   $stdout.print data
      #   $stdout.flush
      # when Array
      #   send data.first, *(data[1..-1].unshift(client))
      # end
    end

    def done
      @mutex.synchronize do
        self.examples_complete += 1
      end
    end

    def next_test
      log "Printer: test size: #{tests_to_run.size}"
      @mutex.synchronize do
        if tests_to_run.size == example_size
          Specjour.configuration.formatter.start_time = Specjour::Time.now
        end
        tests_to_run.shift
      end
    end

    def ready
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
      v = @mutex.synchronize do
        if example_size == 0
          self.tests_to_run = run_order(tests)
          self.example_size = tests_to_run.size
          $stderr.puts "EXAMPLES to run #{tests_to_run.join(" ")}"
          true
        end
      end
      $stderr.puts "register tests is #{v}"
      true
    end

    def report_test(test)
      Specjour.configuration.formatter.report_test(test)
      true
    end

    def find_project_base_dir(directory)
      p ['find in', directory]
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
      if example_size == examples_complete
        @send_threads.each {|t| t.join}
        throw(:stop)
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
      puts "*" * 60
      puts "Oops! The following tests were not run:"
      puts "*" * 60
      puts tests_to_run
      puts "*" * 60
    end

  end
end
