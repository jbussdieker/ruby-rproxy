module RProxy
  class ProxyConnection
    DEBUG = false
    attr_accessor :connection

    def initialize(connection)
      @connection = connection
    end

    def handle_request(req)
      resp, body = issue_upstream(req)
      send_response(req, resp, body)
      resp
    end

    def send_response(req, resp, body)
      type, addrport, addr1, addr2 = connection.peeraddr
      puts "#{Time.now} #{addr1}:#{addrport}  <= HTTP/#{resp.http_version} #{resp.code} #{resp.msg}"

      nresp = Response.new("1.1", resp.code, resp.msg)
      nresp.add_field("Content-Length", body ? body.bytesize : 0)
      nresp.add_field("Connection", req.close? ? "close" : "keep-alive")

      resp.each_header do |k,v|
        unless k == "content-length" || k == "connection"
          nresp.add_field(k.capitalize, v)
        end
      end

      nresp.body = body

      if DEBUG
        puts "Outgoing Response:"
        puts "---------------------------------------"
        puts nresp
        puts
      end

      io.write nresp.to_s
    end

    def issue_upstream(req)
      type, addrport, addr1, addr2 = connection.peeraddr
      puts "#{Time.now} #{addr1}:#{addrport}  => #{req.method} #{req.url} HTTP/#{req.http_version}"

      uri = URI.parse(req.url)
      nreq = Request.new(req.method, uri.request_uri, "1.1")
      req.headers.each do |key, value|
        unless key == "Proxy-Connection" || key == "Connection"
          nreq.add_field(key, value)
        end
      end

      if DEBUG
        puts "Outgoing Request:"
        puts "---------------------------------------"
        puts nreq.to_s
        puts
      end

      socket = TCPSocket.open(uri.host, uri.port)
      upio = Net::BufferedIO.new(socket)
      upio.write(nreq.to_s)
      resp = Response.read_new(upio)
      clen = 0
      resp.each_header do |key, value|
        if key =~ /content-length/i
          clen = value.to_i
        end
      end

      body = upio.read(clen)

      if DEBUG
        puts "Incoming Response:"
        puts "---------------------------------------"
        puts resp.to_s
        puts
      end

      [resp, body]
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

          if DEBUG
            puts "Incoming Request:"
            puts "---------------------------------------"
            puts req
            puts
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
