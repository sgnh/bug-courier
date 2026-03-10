# frozen_string_literal: true

RSpec.describe BugCourier do
  it "has a version number" do
    expect(BugCourier::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "yields the configuration" do
      BugCourier.configure do |config|
        config.access_token = "my-token"
        config.repo = "user/repo"
      end

      expect(BugCourier.configuration.access_token).to eq("my-token")
      expect(BugCourier.configuration.repo).to eq("user/repo")
    end
  end

  describe ".reset!" do
    it "resets the configuration to defaults" do
      BugCourier.configure { |c| c.access_token = "token" }
      BugCourier.reset!

      expect(BugCourier.configuration.access_token).to be_nil
    end
  end
end
