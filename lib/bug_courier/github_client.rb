# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module BugCourier
  class GithubClient
    GITHUB_API_BASE = "https://api.github.com"

    def initialize(access_token:, repo:)
      @access_token = access_token
      @repo = repo
    end

    def create_issue(title:, body:, labels: [], assignees: [])
      uri = URI("#{GITHUB_API_BASE}/repos/#{@repo}/issues")

      payload = {
        title: title,
        body: body,
        labels: labels,
        assignees: assignees
      }.compact

      response = post(uri, payload)

      unless response.is_a?(Net::HTTPCreated)
        BugCourier.logger&.error("[BugCourier] Failed to create GitHub issue: #{response.code} #{response.body}")
        return nil
      end

      JSON.parse(response.body)
    end

    def find_open_issue(title:)
      query = "repo:#{@repo} is:issue is:open in:title #{title}"
      uri = URI("#{GITHUB_API_BASE}/search/issues")
      uri.query = URI.encode_www_form(q: query, per_page: 1)

      response = get(uri)

      unless response.is_a?(Net::HTTPOK)
        BugCourier.logger&.error("[BugCourier] Failed to search GitHub issues: #{response.code} #{response.body}")
        return nil
      end

      data = JSON.parse(response.body)
      items = data["items"] || []
      items.find { |issue| issue["title"] == title }
    end

    def add_comment(issue_number:, body:)
      uri = URI("#{GITHUB_API_BASE}/repos/#{@repo}/issues/#{issue_number}/comments")

      response = post(uri, { body: body })

      unless response.is_a?(Net::HTTPCreated)
        BugCourier.logger&.error("[BugCourier] Failed to add comment to issue ##{issue_number}: #{response.code} #{response.body}")
        return nil
      end

      JSON.parse(response.body)
    end

    private

    def post(uri, payload)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Accept"] = "application/vnd.github+json"
      request["X-GitHub-Api-Version"] = "2022-11-28"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      execute(uri, request)
    end

    def get(uri)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Accept"] = "application/vnd.github+json"
      request["X-GitHub-Api-Version"] = "2022-11-28"

      execute(uri, request)
    end

    def execute(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10
      http.request(request)
    rescue StandardError => e
      BugCourier.logger&.error("[BugCourier] HTTP request failed: #{e.message}")
      nil
    end
  end
end
