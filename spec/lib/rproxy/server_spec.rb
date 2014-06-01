require 'spec_helper'

describe RProxy::Server do
  let(:server) { RProxy::Server.new(host, 0) }
  let(:host) { "127.0.0.1" }
  let(:port) { server.server.addr[1] }

  describe "run" do
    before do
      @thread = Thread.start do
        server.run
      end
      sleep 1
    end

    after do
      @thread.kill
      sleep 1
    end

    it "accepts connections" do
      socket = TCPSocket.open(host, port)
      socket.write("GET / HTTP/1.0\r\n\r\n")
      socket.recv(4096)
    end

    it "works end to end" do
      socket = TCPSocket.open(host, port)
      socket.write("GET http://google.com/ HTTP/1.0\r\n\r\n")
      socket.recv(4096)
    end
  end
end
