module Specjour
  require 'specjour/rspec'
  require 'specjour/cucumber'

  class Printer < GServer
    include Protocol
    RANDOM_PORT = 0

    def self.start(specs_to_run)
      new(specs_to_run).start
    end

    attr_accessor :worker_size, :specs_to_run, :completed_workers, :disconnections, :profiler

    def initialize(specs_to_run)
      super(
        port = RANDOM_PORT,
        host = "0.0.0.0",
        max_connections = 100,
        stdlog = $stderr,
        audit = true,
        debug = true
      )
      @completed_workers = 0
      @disconnections = 0
      @profiler = {}
      self.specs_to_run = run_order(specs_to_run)
    end

    def serve(client)
      client = Connection.wrap client
      client.each(TERMINATOR) do |data|
        process load_object(data), client
      end
    end

    def ready(client)
      synchronize do
        client.print specs_to_run.shift
        client.flush
      end
    end

    def done(client)
      self.completed_workers += 1
    end

    def exit_status
      reporters.all? {|r| r.exit_status == true}
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

    protected

    def disconnecting(client_port)
      self.disconnections += 1
      if disconnections == worker_size
        shutdown
        stop unless Specjour.interrupted?
      end
    end

    def log(msg)
      # noop
    end

    def error(exception)
      Specjour.logger.debug "#{exception.inspect}\n#{exception.backtrace.join("\n")}"
    end

    def process(message, client)
      if message.is_a?(String)
        $stdout.print message
        $stdout.flush
      elsif message.is_a?(Array)
        send(message.first, client, *message[1..-1])
      end
    end

    def run_order(specs_to_run)
      if File.exist?('.specjour/performance')
        ordered_specs = File.readlines('.specjour/performance').map {|l| l.chop.split(':')[1]}
        (specs_to_run - ordered_specs) | (ordered_specs & specs_to_run)
      else
        specs_to_run
      end
    end

    def rspec_report
      @rspec_report ||= Rspec::FinalReport.new
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

    def synchronize(&block)
      @connectionsMutex.synchronize &block
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
