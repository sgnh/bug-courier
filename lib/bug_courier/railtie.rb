# frozen_string_literal: true

require "rails/railtie"

module BugCourier
  class Railtie < Rails::Railtie
    initializer "bug_courier.configure_middleware" do |app|
      app.middleware.insert_before(0, BugCourier::Middleware)
    end

    initializer "bug_courier.set_logger" do
      BugCourier.logger = Rails.logger
    end
  end
end
