module RProxy
  class Server
    attr_accessor :host, :port

    class << self
      def run(host, port)
        new(host, port).run
      end
    end

    def initialize(host, port)
      @host = host
      @port = port
      @pool = []
    end

    def run
      loop do
        accept
      end
    end

    #private

    def accept
      Thread.start(server.accept) do |connection|
        puts @pool.length

        type, addrport, addr1, addr2 = connection.peeraddr
        puts "  #{addr1}:#{addrport} Connection received"

        connection = Connection.new(connection)
        @pool << connection
        connection.run

        puts "  #{addr1}:#{addrport} Connection closed"
        @pool.delete(connection)
      end
    end

    def server
      @server ||= TCPServer.new(host, port)
    end
  end
end
