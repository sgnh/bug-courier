# frozen_string_literal: true

require "bug_courier"
require "webmock/rspec"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    BugCourier.reset!
    BugCourier.configure do |c|
      c.access_token = "fake-token"
      c.repo = "owner/repo"
    end
  end
end
