module Specjour
  class Connection
    include Protocol
    extend Forwardable

    attr_reader :uri
    attr_writer :socket

    def_delegators :socket, :flush, :close, :closed?, :gets, :each

    def self.wrap(established_connection)
      host, port = established_connection.peeraddr.values_at(3,1)
      connection = new URI::Generic.build(:host => host, :port => port)
      connection.socket = established_connection
      connection
    end

    def initialize(uri)
      @uri = uri
    end

    alias to_str to_s

    def connect
      timeout { connect_socket }
    end

    def disconnect
      socket.close
    end

    def socket
      @socket ||= connect
    end

    def timeout(&block)
      Timeout.timeout(2, &block)
    rescue Timeout::Error
      raise Error, "Connection to dispatcher timed out", []
    end

    def next_test
      will_reconnect do
        send_message(:ready)
        load_object socket.gets(TERMINATOR)
      end
    end

    def print(arg)
      will_reconnect do
        socket.print dump_object(arg)
      end
    end

    def puts(arg='')
      print(arg << "\n")
    end

    def send_message(method_name, *args)
      print([method_name, *args])
      flush
    end

    protected

    def connect_socket
      @socket = TCPSocket.open(uri.host, uri.port)
    rescue Errno::ECONNREFUSED => error
      Specjour.logger.debug "Could not connect to #{uri.to_s}\n#{error.inspect}"
      sleep 0.1
      retry
    end

    def reconnect
      socket.close unless socket.closed?
      connect
    end

    def will_reconnect(&block)
      block.call
    rescue SystemCallError => error
      unless Specjour.interrupted?
        reconnect
        retry
      end
    end
  end
end
