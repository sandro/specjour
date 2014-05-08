module Specjour
  class Tester

    def initialize(message)
      @message = message
    end

    def start
      uri = URI::Generic.build host: "127.0.0.1", port: Specjour.configuration.printer_port
      connection = Connection.new uri
      connection.connect
      connection.greet "hi"
      # connection.disconnect
      connection.reconnect
      select [connection.socket]
      # Specjour.benchmark "making requests" do
      # 10000.times do
      #   connection.greet(@message)
      # end
      # end
    end
  end
end
