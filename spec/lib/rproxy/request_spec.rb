require 'spec_helper'

describe RProxy::Request do
  describe "read_new" do
    subject { RProxy::Request.read_new(netio) }
    let(:netio) { Net::BufferedIO.new(io) }
    let(:io) { StringIO.new(data) }
    let(:data) { "GET / HTTP/1.0\r\n" }

    tests = [
      { :method => "GET",  :path => "/", :version => "HTTP/1.0" },
      { :method => "POST", :path => "/", :version => "HTTP/1.0" },

      { :method => "GET",  :path => "/", :version => "HTTP/1.1" },
      { :method => "POST", :path => "/", :version => "HTTP/1.1" },
    ]

    tests.each do |test|
      describe "#{test[:method]} #{test[:path]} #{test[:version]}" do
        let(:data) { "#{test[:method]} #{test[:path]} #{test[:version]}\r\n" }

        it "works" do
          subject
        end
      end
    end

    describe "bad request" do
      let(:data) { "\r\n" }

      it "should raise error" do
        expect {
          subject
        }.to raise_error
      end
    end
  end

  describe "close?" do
    let(:http_version) { "1.0" }
    let(:request) { RProxy::Request.new("GET", "/", http_version) }
    subject { request.close? }

    context "HTTP 1.0" do
      let(:http_version) { "1.0" }

      it { should == true }

      context "Connection: keep-alive" do
        before { request.add_field("Connection", "keep-alive") }
        it { should == true }
      end

      context "Connection: close" do
        before { request.add_field("Connection", "close") }
        it { should == true }
      end
    end
    
    context "HTTP 1.1" do
      let(:http_version) { "1.1" }

      it { should == false }

      context "Connection: keep-alive" do
        before { request.add_field("Connection", "keep-alive") }
        it { should == false }
      end

      context "Connection: close" do
        before { request.add_field("Connection", "close") }
        it { should == true }
      end
    end
  end
end
