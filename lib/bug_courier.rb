# frozen_string_literal: true

require_relative "bug_courier/version"
require_relative "bug_courier/configuration"
require_relative "bug_courier/github_client"
require_relative "bug_courier/exception_handler"
require_relative "bug_courier/middleware"

module BugCourier
  class Error < StandardError; end

  class << self
    attr_accessor :logger

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
    end
  end
end

require_relative "bug_courier/railtie" if defined?(Rails::Railtie)
