module Specjour
  class Connection
    MAX_RECONNECTS = 5

    include Protocol
    extend Forwardable

    attr_reader :uri
    attr_writer :socket
    attr_accessor :reconnection_attempts

    def_delegators :socket, :flush, :closed?, :close, :gets, :each

    def self.wrap(established_connection)
      host, port = established_connection.peeraddr.values_at(2,1)
      connection = new URI::Generic.build(:host => host, :port => port)
      connection.socket = established_connection
      connection
    end

    def initialize(uri)
      @uri = uri
      @reconnection_attempts = 0
    end

    def connect
      @socket = TCPSocket.open(uri.host, uri.port)
    rescue SystemCallError => error
      Kernel.puts "Could not connect to #{uri.to_s}\n#{error.inspect}"
    end

    def socket
      @socket ||= connect
    end

    def print(arg)
      socket.print dump_object(arg)
    rescue SystemCallError => error
      Kernel.p error
      reconnect
      retry
    end

    def puts(arg)
      print(arg << "\n")
    end

    def reconnect
      socket.close
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
