module RProxy
  module Header
    attr_reader :headers

    def add_field(k, v)
      @headers << [k, v]
    end

    def each_header(&block)
      @headers.each do |header|
        yield(header)
      end
    end

    def headers_to_s
      str = @headers.collect {|h| "#{h[0]}: #{h[1]}"}.join("\r\n")
      str += "\r\n" unless @headers.length == 0
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
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
  end
end
