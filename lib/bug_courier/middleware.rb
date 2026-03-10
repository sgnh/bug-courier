# frozen_string_literal: true

module BugCourier
  class Middleware
    def initialize(app)
      @app = app
      @handler = ExceptionHandler.new
    end

    def call(env)
      @app.call(env)
    rescue Exception => exception # rubocop:disable Lint/RescueException
      @handler.handle(exception, env)
      raise
    end
  end
end
