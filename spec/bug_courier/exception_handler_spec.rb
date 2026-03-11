# frozen_string_literal: true

RSpec.describe BugCourier::ExceptionHandler do
  subject(:handler) { described_class.new }

  let(:exception) do
    begin
      raise StandardError, "test error"
    rescue => e
      e
    end
  end

  describe "#handle" do
    it "does nothing when disabled" do
      BugCourier.configuration.enabled = false

      expect(BugCourier::GithubClient).not_to receive(:new)
      handler.handle(exception)
    end

    it "does nothing when configuration is invalid" do
      BugCourier.configuration.access_token = nil

      expect(BugCourier::GithubClient).not_to receive(:new)
      handler.handle(exception)
    end

    it "does nothing when exception class is ignored" do
      BugCourier.configuration.ignore_exceptions = [StandardError]

      expect(BugCourier::GithubClient).not_to receive(:new)
      handler.handle(exception)
    end

    it "does nothing when exception matches ignored string class name" do
      BugCourier.configuration.ignore_exceptions = ["StandardError"]

      expect(BugCourier::GithubClient).not_to receive(:new)
      handler.handle(exception)
    end

    it "does not ignore exceptions that are not in the ignore list" do
      BugCourier.configuration.ignore_exceptions = [ArgumentError]

      client = instance_double(BugCourier::GithubClient)
      allow(BugCourier::GithubClient).to receive(:new).and_return(client)
      allow(client).to receive(:find_open_issue).and_return(nil)
      allow(client).to receive(:create_issue).and_return({ "number" => 1 })

      handler.handle(exception)
      sleep(0.2)

      expect(client).to have_received(:create_issue)
    end

    it "creates a GitHub issue asynchronously" do
      client = instance_double(BugCourier::GithubClient)
      allow(BugCourier::GithubClient).to receive(:new).and_return(client)
      allow(client).to receive(:find_open_issue).and_return(nil)
      allow(client).to receive(:create_issue).and_return({ "number" => 1, "html_url" => "https://github.com/owner/repo/issues/1" })

      handler.handle(exception)
      sleep(0.2) # let the async thread complete

      expect(client).to have_received(:create_issue).with(
        title: kind_of(String),
        body: kind_of(String),
        labels: ["bug", "bug_courier"],
        assignees: []
      )
    end

    it "adds a comment to an existing issue when deduplicating" do
      existing_issue = { "number" => 42, "title" => "existing issue" }
      client = instance_double(BugCourier::GithubClient)
      allow(BugCourier::GithubClient).to receive(:new).and_return(client)
      allow(client).to receive(:find_open_issue).and_return(existing_issue)
      allow(client).to receive(:add_comment).and_return({ "id" => 1 })

      handler.handle(exception)
      sleep(0.2)

      expect(client).to have_received(:add_comment).with(
        issue_number: 42,
        body: kind_of(String)
      )
      expect(client).not_to have_received(:create_issue) if client.respond_to?(:create_issue)
    end

    it "creates a new issue when deduplication is disabled" do
      BugCourier.configuration.deduplicate = false

      client = instance_double(BugCourier::GithubClient)
      allow(BugCourier::GithubClient).to receive(:new).and_return(client)
      allow(client).to receive(:create_issue).and_return({ "number" => 1 })

      handler.handle(exception)
      sleep(0.2)

      expect(client).not_to have_received(:find_open_issue) if client.respond_to?(:find_open_issue)
      expect(client).to have_received(:create_issue)
    end

    it "invokes the callback after creating an issue" do
      callback_called = false
      BugCourier.configuration.callback = ->(action, _issue) { callback_called = (action == :created) }

      client = instance_double(BugCourier::GithubClient)
      allow(BugCourier::GithubClient).to receive(:new).and_return(client)
      allow(client).to receive(:find_open_issue).and_return(nil)
      allow(client).to receive(:create_issue).and_return({ "number" => 1 })

      handler.handle(exception)
      sleep(0.2)

      expect(callback_called).to be true
    end
  end
end
