# frozen_string_literal: true

RSpec.describe BugCourier::Middleware do
  let(:app) { ->(env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  it "passes through successful requests" do
    status, _headers, body = middleware.call({})
    expect(status).to eq(200)
    expect(body).to eq(["OK"])
  end

  it "re-raises exceptions after handling" do
    BugCourier.configuration.enabled = false
    error_app = ->(_env) { raise StandardError, "boom" }
    error_middleware = described_class.new(error_app)

    expect { error_middleware.call({}) }.to raise_error(StandardError, "boom")
  end

  it "calls the exception handler when an error occurs" do
    handler = instance_double(BugCourier::ExceptionHandler)
    allow(BugCourier::ExceptionHandler).to receive(:new).and_return(handler)
    allow(handler).to receive(:handle)

    error_app = ->(_env) { raise StandardError, "test error" }
    error_middleware = described_class.new(error_app)

    expect { error_middleware.call("REQUEST_METHOD" => "GET") }.to raise_error(StandardError)
    expect(handler).to have_received(:handle).with(kind_of(StandardError), kind_of(Hash))
  end
end
