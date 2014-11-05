module Specjour
  module Protocol
    require 'json'

    def recv_data
      bytes = socket.gets.to_i
      string = socket.read(bytes)
      debug "recv_string #{bytes} #{string.inspect}"
      if string
        json = JSON.load(string)
        # log "recv_data: #{bytes} #{json.inspect}"
        json
      end
    end

    def send_data(data)
      json = JSON.dump(data)
      debug "send_data: #{data.inspect}"
      socket.puts  json.bytesize
      socket.write json
    end
  end
end
