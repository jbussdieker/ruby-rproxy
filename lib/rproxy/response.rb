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

    def initialize(httpv, code, msg)
      @http_version = httpv
      @code         = code
      @msg          = msg
      @headers      = []
    end
  end
end
