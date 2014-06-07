module RProxy
  class Response
    include Header

    attr_reader :http_version, :code, :msg
    attr_accessor :body

    def response_line
      "HTTP/#{http_version} #{code} #{msg}\r\n"
    end

    def to_s
      response_line + headers_to_s + "\r\n" + (body || "")
    end

    class << self
      def read_new(sock)   #:nodoc: internal use only
        httpv, code, msg = read_response_line(sock)
        resp = new(httpv, code, msg)
        each_header(sock) do |k, v|
          resp.add_field k, v
        end
        resp
      end

      private

      def read_response_line(sock)
        str = sock.readline
        m = /\AHTTP(?:\/(\d+\.\d+))?\s+(\d+)\s+(.*)(\r\n)?\z/in.match(str) or
          raise Exception, "wrong response line: #{str.dump}"
        m.captures[0..-2]
      end
    end

    def initialize(httpv, code, msg)
      @http_version = httpv
      @code         = code
      @msg          = msg
      @headers      = []
    end
  end
end
