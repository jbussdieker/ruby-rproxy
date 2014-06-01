module RProxy
  class Connection
    attr_accessor :connection

    def initialize(connection)
      @connection = connection
    end

    def handle_request(req)
      puts "#{req.url[0..80]}"
      resp, body = issue_upstream(req)
      send_response(req, resp, body)
      resp
    end

    def send_response(req, resp, body)
      out = "HTTP/1.1 #{resp.code} #{resp.msg}\r\n"
      out << "Content-Length: #{body ? body.length : 0}\r\n"
      out << "Connection: #{req.close? ? "close" : "keep-alive"}\r\n"
      resp.each_header do |k,v|
        unless k == "content-length" || k == "connection"
          out << "#{k.capitalize}: #{v}\r\n"
        end
      end
      out << "\r\n"
      out << (body || "")

      io.write out
    end

    def issue_upstream(req)
      type, addrport, addr1, addr2 = connection.peeraddr
      #puts "  #{addr1}:#{addrport} #{req.method} #{req.url} #{req.http_version}"

      uri = URI.parse(req.url)
      host = uri.host
      port = uri.port
      path = uri.request_uri

      client = Net::HTTP.new(host, port)
      us_req = Net::HTTP.const_get(req.method.capitalize).new(path)
      req.headers.each do |key, value|
        unless key == "Proxy-Connection" || key == "Connection"
          #puts "K: #{key} = #{value}"
          us_req[key] = value
        end
      end

      resp = client.request(us_req)
      body = resp.body
      [resp, body]
    end

    def io
      @io ||= Net::BufferedIO.new(connection)
    end

    def run
      loop {
        begin
          req = Request.read_new(io)
          handle_request(req)

          if req.close?
            connection.close
            break
          end
        rescue Exception => e
          #puts "Exception: #{e.message}"
          e.backtrace.each do |line|
            #puts "  | #{line}"
          end
          io.close
          break
        end
      }
    end
  end
end
