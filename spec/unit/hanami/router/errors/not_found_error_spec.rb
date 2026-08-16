# frozen_string_literal: true

require "hanami/router"
require "hanami/extensions/router/errors"

RSpec.describe(Hanami::Router::NotFoundError) do
  subject(:error) { described_class.new(env) }

  let(:env) { Rack::MockRequest.env_for("http://example.com/example", method: "GET") }

  it "is a Hanami::Router::Error" do
    expect(error.class).to be < Hanami::Router::Error
  end

  it "returns a relevant message" do
    expect(error.to_s).to eq "No route found for GET /example"
  end

  it "returns the env" do
    expect(error.env).to be env
  end

  it "returns no slice by default" do
    expect(error.slice).to be nil
  end

  it "returns the slice it was given" do
    slice = Class.new

    expect(described_class.new(env, slice: slice).slice).to be slice
  end
end
