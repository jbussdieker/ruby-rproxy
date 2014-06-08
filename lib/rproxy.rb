require 'rproxy/server'
require 'rproxy/proxy_connection'
require 'rproxy/header'
require 'rproxy/request'
require 'rproxy/response'
require 'logger'

module RProxy
  @@logger = nil

  def self.logger
    @@logger ||= Logger.new(STDOUT).tap do |logger|
      logger.level = Logger::INFO
    end
  end
end
