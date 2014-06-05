module RProxy
  class Request
    include Header

    attr_reader :method, :url, :http_version
    attr_accessor :body

    def request_line
      "#{method} #{url} HTTP/#{http_version}\r\n"
    end

    def to_s
      request_line + headers_to_s + "\r\n" + (body || "")
    end

    class << self
      def read_new(sock)   #:nodoc: internal use only
        method, url, httpv = read_request_line(sock)
        req = new(method, url, httpv)
        each_header(sock) do |k, v|
          req.add_field k, v
        end
        req
      end

      private

      def read_request_line(sock)
        str = sock.readline
        m = /\A(\w+)\s+(.*)\s+HTTP(?:\/(\d+\.\d+))?(\r\n)?\z/in.match(str) or
          raise Net::HTTPBadResponse, "wrong response line: #{str.dump}"
        m.captures[0..-2]
      end
    end

    def initialize(method, url, httpv)
      @method       = method
      @url          = url
      @http_version = httpv
      @headers      = []
    end

    def [](key)
      @headers.each do |k, v|
        return v if k == key
      end
      nil
    end

    def close?
      http_version == "1.0" || 
      (http_version == "1.1" && self["Connection"] == "close")
    end
  end
end
