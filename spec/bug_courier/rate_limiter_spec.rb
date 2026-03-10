# frozen_string_literal: true

RSpec.describe BugCourier::RateLimiter do
  it "allows requests within the limit" do
    limiter = described_class.new(max_per_hour: 3)
    expect(limiter.allow?).to be true
    expect(limiter.allow?).to be true
    expect(limiter.allow?).to be true
  end

  it "blocks requests exceeding the limit" do
    limiter = described_class.new(max_per_hour: 2)
    expect(limiter.allow?).to be true
    expect(limiter.allow?).to be true
    expect(limiter.allow?).to be false
  end
end
