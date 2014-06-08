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

    def logger
      RProxy.logger
    end

    def run
      logger.info "Starting #{self.class} on #{host}:#{port}"
      loop do
        accept
      end
    end

    #private

    def run_connection(connection)
      #puts @pool.length

      type, addrport, addr1, addr2 = connection.peeraddr
      logger.info "#{addr1}:#{addrport} Connection received"

      connection = ProxyConnection.new(connection)
      @pool << connection
      connection.run

      logger.info "#{addr1}:#{addrport} Connection closed"
      @pool.delete(connection)
    end

    def accept
      Thread.start(server.accept) do |connection|
        run_connection(connection)
      end
    end

    def server
      @server ||= TCPServer.new(host, port)
    end
  end
end
