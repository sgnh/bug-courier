# frozen_string_literal: true

require "digest"

module BugCourier
  class RateLimiter
    def initialize(max_per_hour:)
      @max_per_hour = max_per_hour
      @timestamps = []
      @mutex = Mutex.new
    end

    def allow?
      @mutex.synchronize do
        now = Time.now
        @timestamps.reject! { |t| now - t > 3600 }
        return false if @timestamps.size >= @max_per_hour

        @timestamps << now
        true
      end
    end
  end

  class ExceptionHandler
    def initialize
      @rate_limiter = RateLimiter.new(max_per_hour: BugCourier.configuration.rate_limit)
    end

    def handle(exception, env = {})
      return unless BugCourier.configuration.enabled
      return unless BugCourier.configuration.valid?
      return if ignored?(exception)
      return unless @rate_limiter.allow?

      title = build_title(exception)
      body = build_body(exception, env)

      Thread.new do
        report(title, body)
      rescue StandardError => e
        BugCourier.logger&.error("[BugCourier] Async reporting failed: #{e.message}")
      end
    end

    private

    def report(title, body)
      config = BugCourier.configuration
      client = GithubClient.new(access_token: config.access_token, repo: config.repo)

      if config.deduplicate
        existing = client.find_open_issue(title: title)
        if existing
          client.add_comment(
            issue_number: existing["number"],
            body: "**This error occurred again at #{Time.now.utc.iso8601}**\n\n#{body}"
          )
          config.callback&.call(:comment, existing)
          return
        end
      end

      result = client.create_issue(
        title: title,
        body: body,
        labels: config.labels,
        assignees: config.assignees
      )

      config.callback&.call(:created, result) if result
    end

    def build_title(exception)
      location = exception.backtrace&.first&.gsub(Dir.pwd, ".")&.slice(0, 80) || "unknown"
      "[BugCourier] #{exception.class}: #{exception.message.slice(0, 100)} (#{location})"
    end

    def build_body(exception, env)
      request_info = extract_request_info(env)
      fingerprint = Digest::SHA256.hexdigest("#{exception.class}#{exception.backtrace&.first}")[0, 12]

      parts = []
      parts << "## #{exception.class}"
      parts << ""
      parts << "**Message:** #{exception.message}"
      parts << ""
      parts << "**Fingerprint:** `#{fingerprint}`"
      parts << ""

      if request_info.any?
        parts << "## Request Details"
        parts << ""
        request_info.each { |k, v| parts << "- **#{k}:** `#{v}`" }
        parts << ""
      end

      parts << "## Backtrace"
      parts << ""
      parts << "```"
      backtrace = exception.backtrace || ["No backtrace available"]
      parts << backtrace.first(30).join("\n")
      parts << "```"
      parts << ""
      parts << "---"
      parts << "*Reported by [BugCourier](https://github.com/sgnh/bug-courier) at #{Time.now.utc.iso8601}*"

      parts.join("\n")
    end

    def extract_request_info(env)
      return {} if env.nil? || env.empty?

      info = {}

      if env.is_a?(Hash)
        request = env["action_dispatch.request"] || (defined?(ActionDispatch::Request) && ActionDispatch::Request.new(env))

        if request
          info["Method"] = request.request_method rescue nil
          info["URL"] = request.original_url rescue nil
          info["IP"] = request.remote_ip rescue nil
          info["User-Agent"] = request.user_agent rescue nil
          info["Params"] = filtered_params(request) rescue nil
        else
          info["Method"] = env["REQUEST_METHOD"] if env["REQUEST_METHOD"]
          info["Path"] = env["PATH_INFO"] if env["PATH_INFO"]
          info["IP"] = env["REMOTE_ADDR"] if env["REMOTE_ADDR"]
        end
      end

      info.compact
    end

    def filtered_params(request)
      params = request.filtered_parameters rescue request.params rescue nil
      return nil if params.nil? || params.empty?

      params.except("controller", "action").to_s.slice(0, 500)
    end

    def ignored?(exception)
      BugCourier.configuration.ignore_exceptions.any? do |klass|
        klass = Object.const_get(klass) if klass.is_a?(String)
        exception.is_a?(klass)
      rescue NameError
        false
      end
    end
  end
end
