require 'logger'

module RProxy
  class ProxyConnection
    attr_accessor :connection, :options

    def initialize(connection, options = {})
      @connection = connection
      @options = options
    end

    def logger
      options[:logger]
    end

    def handle_request(req)
      resp, body = issue_upstream(req)
      send_response(req, resp, body)
      resp
    end

    def transform_request(req)
      uri = URI.parse(req.url)

      req.remove_field("Proxy-Connection")
      req.remove_field("Connection")
      req.url = uri.request_uri

      [req, uri]
    end

    def issue_upstream(req)
      type, addrport, addr1, addr2 = connection.peeraddr
      logger.info "#{addr1}:#{addrport}  => #{req.method} #{req.url} HTTP/#{req.http_version}"

      req, uri = transform_request(req)

      socket = TCPSocket.open(uri.host, uri.port)
      upio = Net::BufferedIO.new(socket)
      upio.write(req.to_s)
      resp = Response.read_new(upio)
      clen = resp["Content-Length"].to_i
      body = upio.read(clen)

      [resp, body]
    end

    def transform_response(req, resp, body)
      resp.remove_field("Content-Length")
      resp.remove_field("Connection")
      resp.add_field("Content-Length", body ? body.bytesize : 0)
      resp.add_field("Connection", req.close? ? "close" : "keep-alive")
      resp.body = body

      [resp, body]
    end

    def send_response(req, resp, body)
      type, addrport, addr1, addr2 = connection.peeraddr
      logger.info "#{addr1}:#{addrport}  <= HTTP/#{resp.http_version} #{resp.code} #{resp.msg}"

      resp, body = transform_response(req, resp, body)

      io.write resp.to_s
    end

    def io
      @io ||= Net::BufferedIO.new(connection)
    end

    def run
      loop {
        begin
          begin
            req = Request.read_new(io)
          rescue Exception => e
            if e.message == "end of file reached"
              #puts "Normalish close"
              connection.close
              break
            else
              puts "Exception: #{e.message}"
              e.backtrace.each do |line|
                puts "  | #{line}"
              end
            end
          end

          handle_request(req)

          if req.close?
            connection.close
            break
          end
        rescue Exception => e
          puts "Exception: #{e.message}"
          e.backtrace.each do |line|
            puts "  | #{line}"
          end
          io.close
          break
        end
      }
    end
  end
end
