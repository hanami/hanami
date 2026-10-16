# frozen_string_literal: true

require "hanami/router"
require "hanami/extensions/router/errors"

RSpec.describe(Hanami::Router::NotAllowedError) do
  subject(:error) { described_class.new(env, allowed_methods) }

  let(:env) { Rack::MockRequest.env_for("http://example.com/example", method: "POST") }
  let(:allowed_methods) { ["GET", "HEAD"] }

  it "is a Hanami::Router::Error" do
    expect(error.class).to be < Hanami::Router::Error
  end

  it "returns a relevant message" do
    expect(error.to_s).to eq "Only GET, HEAD requests are allowed at /example"
  end

  it "returns the env" do
    expect(error.env).to be env
  end

  it "returns the allowed methods" do
    expect(error.allowed_methods).to be allowed_methods
  end

  it "returns no slice by default" do
    expect(error.slice).to be nil
  end

  it "returns the slice it was given" do
    slice = Class.new

    expect(described_class.new(env, allowed_methods, slice: slice).slice).to be slice
  end
end
