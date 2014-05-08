module Specjour
  module Protocol
    require 'json'

    def recv_data
      bytes = socket.gets.to_i
      json = JSON.load socket.read(bytes)
      log "recv_data: #{bytes} #{json.inspect}"
      json
    end

    def send_data(data)
      json = JSON.dump(data)
      log "send_data: #{data.inspect}"
      socket.puts  json.bytesize
      socket.write json
    end
  end
end
