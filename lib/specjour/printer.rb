module Specjour
  class Printer < GServer
    include Protocol
    RANDOM_PORT = 0

    def self.start(specs_to_run)
      new(specs_to_run).start
    end

    attr_accessor :worker_size, :specs_to_run, :completed_workers

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
      self.specs_to_run = specs_to_run
    end

    def serve(client)
      client = Connection.wrap client
      client.each(TERMINATOR) do |data|
        process load_object(data), client
      end
    end

    def ready(client)
      client.print specs_to_run.shift
      client.flush
    end

    def done(client)
      self.completed_workers += 1
    end

    def worker_summary=(client, summary)
      report.add(summary)
    end

    protected

    def disconnecting(client_port)
      if completed_workers == worker_size
        stop
      end
    end

    def log(msg)
      # noop
    end

    def process(message, client)
      if message.is_a?(String)
        $stdout.print message
        $stdout.flush
      elsif message.is_a?(Array)
        send(message.first, client, *message[1..-1])
      end
    end

    def report
      @report ||= Rspec::FinalReport.new
    end

    def stopping
      report.summarize
    end
  end
end
