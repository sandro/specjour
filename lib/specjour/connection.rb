module Specjour
  class Connection
    MAX_RECONNECTS = 5

    include Protocol
    extend Forwardable

    attr_reader :uri, :connection
    attr_accessor :reconnection_attempts

    def_delegators :connection, :flush, :closed?, :close, :gets, :each

    def initialize(uri)
      @uri = uri
      @reconnection_attempts = 0
      connect
    end

    def connect
      @connection = TCPSocket.open(uri.host, uri.port)
    rescue SystemCallError => error
      Kernel.puts "Could not connect to #{uri.to_s}\n#{error.inspect}"
    end

    def print(arg)
      connection.print dump_object(arg)
    rescue SystemCallError => error
      Kernel.p error
      reconnect
      retry
    end

    def puts(arg)
      print(arg << "\n")
    end

    def reconnect
      connection.close
      if reconnection_attempts < MAX_RECONNECTS
        connect
        self.reconnection_attempts += 1
      else
        raise Error, "Lost connection #{MAX_RECONNECTS} times"
      end
    end

    def send_message(method_name, *args)
      print([method_name, *args])
      flush
    end
  end
end
