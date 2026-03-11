# frozen_string_literal: true

module BugCourier
  class Configuration
    attr_accessor :access_token, :repo, :labels, :assignees, :enabled,
                  :deduplicate, :rate_limit, :callback, :ignore_exceptions

    def initialize
      @access_token = nil
      @repo = nil
      @labels = ["bug", "bug_courier"]
      @assignees = []
      @enabled = true
      @deduplicate = true
      @rate_limit = 10 # max issues per hour
      @callback = nil
      @ignore_exceptions = []
    end

    def valid?
      !!(access_token && !access_token.empty? && repo && !repo.empty?)
    end
  end
end
