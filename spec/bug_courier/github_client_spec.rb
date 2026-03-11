# frozen_string_literal: true

RSpec.describe BugCourier::GithubClient do
  subject(:client) { described_class.new(access_token: "fake-token", repo: "owner/repo") }

  describe "#create_issue" do
    it "sends a POST request to the GitHub API" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .with(
          headers: { "Authorization" => "Bearer fake-token", "Accept" => "application/vnd.github+json" },
          body: hash_including("title" => "Test Issue", "body" => "Test body")
        )
        .to_return(status: 201, body: '{"number": 1, "html_url": "https://github.com/owner/repo/issues/1"}', headers: { "Content-Type" => "application/json" })

      result = client.create_issue(title: "Test Issue", body: "Test body", labels: ["bug"])
      expect(stub).to have_been_requested
      expect(result["number"]).to eq(1)
    end

    it "returns nil on failure" do
      stub_request(:post, "https://api.github.com/repos/owner/repo/issues")
        .to_return(status: 422, body: '{"message": "Validation Failed"}')

      result = client.create_issue(title: "Test", body: "Test")
      expect(result).to be_nil
    end

    it "returns nil when the HTTP request fails" do
      allow(client).to receive(:post).and_return(nil)

      expect(client.create_issue(title: "Test", body: "Test")).to be_nil
    end
  end

  describe "#find_open_issue" do
    it "searches for an existing open issue" do
      stub = stub_request(:get, "https://api.github.com/search/issues")
        .with(query: hash_including("q" => /owner\/repo.*is:issue.*is:open/))
        .to_return(
          status: 200,
          body: '{"items": [{"number": 42, "title": "Test Issue"}]}',
          headers: { "Content-Type" => "application/json" }
        )

      result = client.find_open_issue(title: "Test Issue")
      expect(stub).to have_been_requested
      expect(result["number"]).to eq(42)
    end

    it "returns nil when no matching issue found" do
      stub_request(:get, /api\.github\.com\/search\/issues/)
        .to_return(status: 200, body: '{"items": []}', headers: { "Content-Type" => "application/json" })

      result = client.find_open_issue(title: "Non-existent")
      expect(result).to be_nil
    end

    it "returns nil when the search request fails" do
      allow(client).to receive(:get).and_return(nil)

      expect(client.find_open_issue(title: "Test Issue")).to be_nil
    end
  end

  describe "#add_comment" do
    it "posts a comment to an existing issue" do
      stub = stub_request(:post, "https://api.github.com/repos/owner/repo/issues/42/comments")
        .with(body: hash_including("body" => "Occurred again"))
        .to_return(status: 201, body: '{"id": 1}', headers: { "Content-Type" => "application/json" })

      result = client.add_comment(issue_number: 42, body: "Occurred again")
      expect(stub).to have_been_requested
      expect(result["id"]).to eq(1)
    end

    it "returns nil when the comment request fails" do
      allow(client).to receive(:post).and_return(nil)

      expect(client.add_comment(issue_number: 42, body: "Occurred again")).to be_nil
    end
  end
end
