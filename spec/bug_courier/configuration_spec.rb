# frozen_string_literal: true

RSpec.describe BugCourier::Configuration do
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.labels).to eq(["bug", "bug_courier"])
    expect(config.assignees).to eq([])
    expect(config.enabled).to be true
    expect(config.deduplicate).to be true
    expect(config.rate_limit).to eq(10)
  end

  describe "#valid?" do
    it "returns false without access_token" do
      config.repo = "owner/repo"
      expect(config.valid?).to be false
    end

    it "returns false without repo" do
      config.access_token = "token"
      expect(config.valid?).to be false
    end

    it "returns true with access_token and repo" do
      config.access_token = "token"
      config.repo = "owner/repo"
      expect(config.valid?).to be true
    end

    it "returns false with blank access_token" do
      config.access_token = ""
      config.repo = "owner/repo"
      expect(config.valid?).to be false
    end
  end
end
