module Specjour
  module SocketHelper
    Socket.do_not_reverse_lookup = true

    def connection
      return @connection if connection?
      debug "CONNECTING #{self.class.name}"
      @connection = Connection.new Specjour.configuration.printer_uri
      @connection.connect
      @connection
    end

    def connection?
      !@connection.nil?
    end

    def current_uri
      @current_uri ||= new_uri
    end

    def remove_connection
      connection.disconnect if connection?
      @connection = nil
    end

    module_function

    def new_uri
      URI::Generic.build :host => faux_server[2], :port => faux_server[1]
    end

    def ip_from_hostname(hostname)
      Socket.getaddrinfo(hostname, nil, Socket::AF_INET, Socket::SOCK_STREAM).first.fetch(3)
    rescue SocketError
      hostname
    end

    def hostname
      Socket.gethostname
    end

    def local_ip
      UDPSocket.open {|s| s.connect('74.125.224.103', 1); s.addr.last }
    end

    def remote_ip?(ip)
      Socket.ip_address_list.detect {|a| a.ip_address == ip}.nil?
    end

    def faux_server
      server = TCPServer.new('0.0.0.0', nil)
      server.addr
    ensure
      server.close
    end
  end
end
