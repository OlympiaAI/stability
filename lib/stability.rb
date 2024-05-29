# frozen_string_literal: true

require_relative "stability/http"
require_relative "stability/client"
require_relative "stability/version"

module Stability
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class Configuration
    attr_writer :api_key
    attr_accessor :api_version, :extra_headers, :faraday_config, :log_errors, :request_timeout, :uri_base

    DEFAULT_API_VERSION = "v2beta"
    DEFAULT_REQUEST_TIMEOUT = 120
    DEFAULT_URI_BASE = "https://api.stability.ai"

    def initialize
      self.api_key = nil
      self.api_version = DEFAULT_API_VERSION
      self.extra_headers = {}
      self.log_errors = false
      self.request_timeout = DEFAULT_REQUEST_TIMEOUT
      self.uri_base = DEFAULT_URI_BASE
    end

    def api_key
      return @api_key if @api_key

      raise ConfigurationError, "Stability AI api key missing!"
    end

    def faraday(&block)
      self.faraday_config = block
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Stability::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
