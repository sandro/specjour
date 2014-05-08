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
    )

    def initialize(options={})
      @options = options
      @host = "0.0.0.0"
      @server_socket = TCPServer.new(@host, Specjour.configuration.printer_port)
      @port = @server_socket.addr[1]
      @profiler = {}
      @clients = {}
      @tests_to_run = []
      @test_paths = options[:test_paths]
      @example_size = 0
      @machines = []
      @formatter = Specjour.configuration.formatter
      self.examples_complete = 0
    end

    def announce
      text = DNSSD::TextRecord.new
      text['version'] = Specjour::VERSION
      projects = []
      DNSSD.register "#{projects.join(",")}@#{hostname}".tr(".","-"), "_specjour._tcp", domain=nil, Specjour.configuration.printer_port, text
    end

    def start_rsync
      rsync_daemon.start
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name, Specjour.configuration.rsync_port)
    end

    def start
      fds = [@server_socket]
      catch(:stop) do
        while true
          reads = select(fds).first
          reads.each do |socket_being_read|
            if socket_being_read == @server_socket
              log "adding connection"
              client_socket = @server_socket.accept
              fds << client_socket
              clients[client_socket] = Connection.wrap(client_socket)
            elsif socket_being_read.eof?
              log "closing connection"
              socket_being_read.close
              fds.delete(socket_being_read)
              clients.delete(socket_being_read)
              # disconnecting
            else
              log "serving"
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

    protected

    def serve(client)
      data = client.recv_data
      if COMMANDS.include?(data['command'])
        client.send_data send(data['command'], *data['args'])
      end
      # case data
      # when String
      #   $stdout.print data
      #   $stdout.flush
      # when Array
      #   send data.first, *(data[1..-1].unshift(client))
      # end
    end

    def done
      self.examples_complete += 1
    end

    def next_test
      log "Printer test size: #{tests_to_run.size}"
      tests_to_run.shift
    end

    def ready
      { project_name: project_name, test_paths: test_paths }
    end

    def greet(message)
      { received: message }
    end

    def register_tests(tests)
      if tests_to_run.empty?
        self.tests_to_run = run_order(tests)
        self.example_size = tests_to_run.size
        true
      end
    end

    def project_path
      Dir.pwd
    end

    def options
      {}
    end

    def project_name
      options[:project_alias] || File.basename(project_path)
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
      if clients.empty?
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

    def reporters
      [@rspec_report, @cucumber_report].compact
    end

    def stopping
      summarize_reports
      unless Specjour.interrupted?
        record_performance
        print_missing_tests if missing_tests?
      end
    end

    def summarize_reports
      reporters.each {|r| r.summarize}
    end

    def missing_tests?
      tests_to_run.any? || examples_complete != example_size
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
