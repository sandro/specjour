module Specjour

  class Printer
    include Protocol
    RANDOM_PORT = 0

    attr_reader :port, :clients
    attr_accessor :tests_to_run, :example_size, :examples_complete, :profiler

    def initialize
      @host = "0.0.0.0"
      @server_socket = TCPServer.new(@host, RANDOM_PORT)
      @port = @server_socket.addr[1]
      @profiler = {}
      @clients = {}
      @tests_to_run = []
      @example_size = 0
      self.examples_complete = 0
    end

    def start
      fds = [@server_socket]
      catch(:stop) do
        while true
          reads = select(fds).first
          reads.each do |socket_being_read|
            if socket_being_read == @server_socket
              client_socket = @server_socket.accept
              fds << client_socket
              clients[client_socket] = Connection.wrap(client_socket)
            elsif socket_being_read.eof?
              socket_being_read.close
              fds.delete(socket_being_read)
              clients.delete(socket_being_read)
              disconnecting
            else
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
      reporters.all? {|r| r.exit_status == true}
    end

    protected

    def serve(client)
      data = load_object(client.gets(TERMINATOR))
      case data
      when String
        $stdout.print data
        $stdout.flush
      when Array
        send data.first, *(data[1..-1].unshift(client))
      end
    end

    def ready(client)
      client.print tests_to_run.shift
      client.flush
    end

    def done(client)
      self.examples_complete += 1
    end

    def tests=(client, tests)
      if tests_to_run.empty?
        self.tests_to_run = run_order(tests)
        self.example_size = tests_to_run.size
      end
    end

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
      if (examples_complete == example_size) || clients.empty?
        throw(:stop)
      end
    end

    def run_order(tests)
      if File.exist?('.specjour/performance')
        ordered_tests = File.readlines('.specjour/performance').map {|l| l.chop.split(':', 2)[1]}
        (tests - ordered_tests) | (ordered_tests & tests)
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
      record_performance unless Specjour.interrupted?
      print_missing_tests if tests_to_run.any?
    end

    def summarize_reports
      reporters.each {|r| r.summarize}
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
