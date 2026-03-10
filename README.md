# BugCourier

A Rails gem that automatically creates GitHub issues when uncaught exceptions occur. Includes deduplication (comments on existing open issues instead of creating duplicates), rate limiting, request context capture, and async reporting.

## Auto-Fix Bugs with GitHub Copilot

BugCourier turns your production exceptions into GitHub issues — and **GitHub Copilot can automatically fix them**.

When Copilot is enabled on your repository, it can pick up BugCourier-created issues (complete with backtraces, request context, and error fingerprints) and open pull requests with fixes. This creates a powerful loop:

1. An uncaught exception occurs in production
2. BugCourier creates a detailed GitHub issue with the full error context
3. Copilot reads the issue and opens a PR with a proposed fix
4. You review and merge

No manual triage. No copying stack traces. Just assign Copilot to BugCourier issues and let it work.

## Installation

Add to your Gemfile:

```ruby
gem "bug_courier"
```

Then run:

```bash
bundle install
rails generate bug_courier:install
```

This creates an initializer at `config/initializers/bug_courier.rb`.

## Configuration

```ruby
BugCourier.configure do |config|
  # Required: GitHub personal access token with 'repo' scope
  config.access_token = ENV["BUG_COURIER_GITHUB_TOKEN"]

  # Required: GitHub repository in "owner/repo" format
  config.repo = ENV["BUG_COURIER_GITHUB_REPO"]

  # Labels applied to created issues (default: ["bug", "bug_courier"])
  config.labels = ["bug", "bug_courier"]

  # GitHub usernames to assign (default: [])
  config.assignees = ["your-github-username"]

  # Enable/disable (default: true)
  config.enabled = Rails.env.production?

  # Deduplicate — comments on existing open issues instead of creating new ones (default: true)
  config.deduplicate = true

  # Max issues created per hour (default: 10)
  config.rate_limit = 10

  # Optional callback after issue creation/commenting
  config.callback = ->(action, issue) {
    Rails.logger.info("[BugCourier] #{action}: #{issue['html_url']}")
  }
end
```

### GitHub Token

Create a [GitHub personal access token](https://github.com/settings/tokens) with the `repo` scope (or `public_repo` for public repositories). Set it as the `BUG_COURIER_GITHUB_TOKEN` environment variable.

## How It Works

1. BugCourier inserts a Rack middleware at the top of your middleware stack
2. When an uncaught exception propagates up, the middleware catches it, reports it asynchronously, then re-raises it so normal error handling continues
3. If deduplication is enabled, it searches for an existing open issue with the same title and adds a comment instead of creating a duplicate
4. Rate limiting prevents flooding your repository with issues during error spikes

### What Gets Reported

Each issue includes:

- **Exception class and message**
- **Full backtrace** (first 30 lines)
- **Request details** — method, URL, IP, user agent, filtered params
- **Fingerprint** — SHA256 hash for identifying duplicate errors

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
