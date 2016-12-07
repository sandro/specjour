module Specjour
  module Protocol
    require 'json'

    def recv_data
      bytes = socket.gets.to_i
      string = socket.read(bytes)
      debug "recv_string #{bytes} #{string.inspect} #{socket.inspect}"
      if !string.empty?
        Marshal.load(string)
      end
    end

    def send_data(data)
      mdata = Marshal.dump(data)
      debug "send_data: #{mdata.bytesize} #{mdata.inspect} #{socket.inspect}"
      socket.puts  mdata.bytesize
      socket.write mdata
    end
  end
end
