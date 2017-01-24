module Specjour
  class Connection
    include Logger
    include Protocol
    extend Forwardable

    attr_reader :uri, :retries
    attr_writer :socket

    def_delegators :socket, :flush, :close, :closed?, :gets, :puts, :each, :eof?, :tty?

    def self.wrap(established_connection)
      host, port = established_connection.peeraddr.values_at(3,1)
      connection = new URI::Generic.build(:host => host, :port => port)
      connection.socket = established_connection
      connection
    end

    def initialize(uri)
      @uri = uri
      @retries = 0
    end

    alias to_str to_s

    def connect
      debug "connecting to socket #{host}:#{port}"
      timeout { connect_socket }
    end

    def disconnect
      if socket && !socket.closed?
        debug "closing socket"
        socket.close
      end
    end

    def host
      uri.host
    end

    def port
      uri.port
    end

    def socket
      @socket ||= connect
    end

    def add_to_profiler(test, time, host)
      send_command("add_to_profiler", test, time, host)
    end

    def done
      send_command("done")
    end

    def error(exception)
      prefix = if n = ENV["TEST_ENV_NUMBER"]
                 "[#{n}]"
               else
                 ""
               end
      send_command("error", "#{prefix}#{exception.inspect}\n#{exception.backtrace.join("\n")}")
    rescue => error
      $stderr.puts "Error sending error to server: #{error.inspect}"
      $stderr.puts error.backtrace
    end

    def report_test(test)
      send_command("report_test", test)
    end

    def next_test
      send_recv_command("next_test")
    end

    def ready(info)
      send_recv_command("ready", info)
    end

    def reconnect
      socket.close unless socket.closed?
      connect
    end

    def register_tests(tests)
      send_command("register_tests", tests)
    end

    def send_server_done(signal)
      send_command("server_done", signal)
    end

    def get_server_done
      will_reconnect do
        data = recv_data
        if data[:command] == "server_done"
          data[:args].first
        end
      end
    end

    def send_command(method_name, *args)
      will_reconnect do
        send_data command: method_name, args: args
      end
    end

    def send_recv_command(method_name, *args)
      send_command(method_name, *args)
      will_reconnect do
        recv_data
      end
    end

    protected

    def connect_socket
      @socket = TCPSocket.open(host, port)
    rescue Errno::ECONNREFUSED => error
      retry
    end

    def timeout(&block)
      Timeout.timeout(0.2, &block)
    rescue Timeout::Error
    end

    def will_reconnect(&block)
      block.call
    rescue SystemCallError, IOError => error
      unless Specjour.interrupted?
        @retries += 1
        reconnect
        retry if retries <= 5
      end
    end
  end
end
