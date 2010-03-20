module Specjour
  class Printer < GServer
    include Protocol
    RANDOM_PORT = 0

    attr_reader :completed_workers
    attr_accessor :worker_size

    def initialize
      super(
        port = RANDOM_PORT,
        host = "0.0.0.0",
        max_connections = 100,
        stdlog = $stderr,
        audit = true,
        debug = true
      )
      @completed_workers = 0
    end

    def serve(client)
      client.each(TERMINATOR) do |data|
        process load_object(data)
      end
    end

    def worker_summary=(summary)
      report.add(summary)
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    protected

    def disconnecting(client_port)
      @completed_workers += 1
      if completed_workers == worker_size
        stop
      end
    end

    def log(msg)
      #noop
    end

    def process(message)
      if message.is_a?(String)
        $stdout.print message
        $stdout.flush
      elsif message.is_a?(Array)
        send(message.first, message[1])
      end
    end

    def report
      @report ||= FinalReport.new
    end

    def stopping
      report.summarize
    end
  end
end
