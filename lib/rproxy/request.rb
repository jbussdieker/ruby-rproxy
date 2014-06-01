module RProxy
  class Request
    attr_reader :method, :url, :http_version, :headers

    def request_line
      "#{method} #{url} HTTP/#{http_version}\r\n"
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

      def each_header(sock)
        key = value = nil
        while true
          line = sock.readuntil("\n", true).sub(/\s+\z/, '')
          break if line.empty?
          if line[0] == ?\s or line[0] == ?\t and value
            value << ' ' unless value.empty?
            value << line.strip
          else
            yield key, value if key
            key, value = line.strip.split(/\s*:\s*/, 2)
            raise Net::HTTPBadResponse, 'wrong header line format' if value.nil?
          end
        end
        yield key, value if key
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

    def add_field(k, v)
      @headers << [k, v]
    end
  end
end
