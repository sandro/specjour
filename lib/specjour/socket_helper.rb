module Specjour
  module SocketHelper
    def ip_from_hostname(hostname)
      Socket.getaddrinfo(hostname, nil, Socket::AF_INET, Socket::SOCK_STREAM).first.fetch(3)
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def current_uri
      @current_uri ||= new_uri
    end

    def new_uri
      URI::Generic.build :host => faux_server[2], :port => faux_server[1]
    end

    protected

    def faux_server
      server = TCPServer.new('0.0.0.0', nil)
      server.addr
    ensure
      server.close
    end
  end
end
