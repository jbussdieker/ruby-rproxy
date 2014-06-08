require 'spec_helper'

describe RProxy::Response do
  describe "read_new" do
    subject { RProxy::Response.read_new(netio) }
    let(:netio) { Net::BufferedIO.new(io) }
    let(:io) { StringIO.new(data) }
    let(:data) { "HTTP/1.0 200 OK\r\n" }

    tests = [
      { :code => 200, :msg => "OK", :version => "HTTP/1.0" },
      { :code => 302, :msg => "Moved Permenantly", :version => "HTTP/1.0" },

      { :code => 200, :msg => "OK", :version => "HTTP/1.1" },
      { :code => 302, :msg => "Moved Permenantly", :version => "HTTP/1.1" },
    ]

    tests.each do |test|
      describe "#{test[:version]} #{test[:code]} #{test[:msg]}" do
        let(:data) { "#{test[:version]} #{test[:code]} #{test[:msg]}\r\n" }

        it "works" do
          subject
        end
      end
    end
  end
end
