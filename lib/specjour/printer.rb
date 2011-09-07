module Specjour
  require 'specjour/rspec'
  require 'specjour/cucumber'

  class Printer
    include Protocol
    RANDOM_PORT = 0

    attr_reader :port
    attr_accessor :worker_size, :tests_to_run, :completed_workers, :disconnections, :profiler

    def initialize(tests_to_run)
      @host = "0.0.0.0"
      @server_socket = TCPServer.new(@host, RANDOM_PORT)
      @port = @server_socket.addr[1]
      @completed_workers = 0
      @disconnections = 0
      @profiler = {}
      self.tests_to_run = run_order(tests_to_run)
    end

    def start
      fds = [@server_socket]
      clients = {}
      catch(:stop) do
        while true
          reads = select(fds).first
          reads.each do |socket|
            if socket == @server_socket
              socket = @server_socket.accept
              fds << socket
              clients[socket] = Connection.wrap(socket)
            elsif socket.eof?
              fds.delete(socket)
              socket.close
              disconnecting
            else
              serve(clients[socket])
            end
          end
        end
      end
    ensure
      stopping
      fds.each {|c| c.close}
    end

    def serve(client)
      data = load_object(client.gets(TERMINATOR))
      case data
      when String
        $stdout.print data
        $stdout.flush
      when Array
        if data.first == :ready
          ready(client)
        else
          send(data.first, *data[1..-1])
        end
      end
    end

    def ready(client)
      client.print tests_to_run.shift
      client.flush
    end

    def done
      self.completed_workers += 1
    end

    def exit_status
      reporters.all? {|r| r.exit_status == true}
    end

    def rspec_summary=(summary)
      rspec_report.add(summary)
    end

    def cucumber_summary=(summary)
      cucumber_report.add(summary)
    end

    def add_to_profiler(args)
      test, time = *args
      self.profiler[test] = time
    end

    protected

    def disconnecting
      self.disconnections += 1
      if disconnections == worker_size
        throw(:stop) unless Specjour.interrupted?
      end
    end

    def run_order(tests)
      if File.exist?('.specjour/performance')
        ordered_tests = File.readlines('.specjour/performance').map {|l| l.chop.split(':')[1]}
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
      warn_if_workers_deserted
      record_performance unless Specjour.interrupted?
    end

    def summarize_reports
      reporters.each {|r| r.summarize}
    end

    def warn_if_workers_deserted
      if disconnections != completed_workers && !Specjour.interrupted?
        puts
        puts workers_deserted_message
      end
    end

    def workers_deserted_message
      data = "* ERROR: NOT ALL WORKERS COMPLETED PROPERLY *"
      filler = "*" * data.size
      [filler, data, filler].join "\n"
    end
  end
end
