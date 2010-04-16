module Specjour
  module SocketHelpers
    def ip_from_hostname(hostname)
      Socket.getaddrinfo(hostname, nil, Socket::AF_INET, Socket::SOCK_STREAM).first.fetch(3)
    end

    def hostname
      @hostname ||= Socket.gethostname
    end
  end
end
