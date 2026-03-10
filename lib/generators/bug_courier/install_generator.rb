# frozen_string_literal: true

require "rails/generators"

module BugCourier
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates a BugCourier initializer file at config/initializers/bug_courier.rb"

      def create_initializer_file
        create_file "config/initializers/bug_courier.rb", <<~RUBY
          # frozen_string_literal: true

          BugCourier.configure do |config|
            # Required: GitHub personal access token with 'repo' scope
            config.access_token = ENV["BUG_COURIER_GITHUB_TOKEN"]

            # Required: GitHub repository in "owner/repo" format
            config.repo = ENV["BUG_COURIER_GITHUB_REPO"]

            # Labels to apply to created issues (default: ["bug", "bug_courier"])
            # config.labels = ["bug", "bug_courier"]

            # GitHub usernames to assign to created issues (default: [])
            # config.assignees = ["your-github-username"]

            # Enable/disable BugCourier (default: true)
            # config.enabled = Rails.env.production?

            # Deduplicate issues — adds comments to existing open issues instead
            # of creating new ones (default: true)
            # config.deduplicate = true

            # Maximum number of issues to create per hour (default: 10)
            # config.rate_limit = 10

            # Optional callback — called after issue creation or commenting
            # config.callback = ->(action, issue) {
            #   Rails.logger.info("[BugCourier] \#{action}: \#{issue['html_url']}")
            # }
          end
        RUBY
      end
    end
  end
end
