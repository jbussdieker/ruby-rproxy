require 'logger'

module RProxy
  class Server
    attr_accessor :host, :port, :options

    class << self
      def run(host, port)
        new(host, port).run
      end
    end

    def initialize(host, port, options = {})
      @host = host
      @port = port
      @options = options
      @pool = []
    end

    def logger
      options[:logger] ||= Logger.new(STDOUT).tap do |logger|
        logger.level = Logger::INFO
      end
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

      connection = ProxyConnection.new(connection, options)
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
