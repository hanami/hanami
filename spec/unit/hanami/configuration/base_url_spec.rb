# frozen_string_literal: true

require "hanami/configuration"
require "uri"

RSpec.describe Hanami::Configuration, "base_url" do
  subject(:config) { described_class.new(application_name: application_name, env: :development) }
  let(:application_name) { "MyApp::Application" }

  it "defaults to a URI of 'http://0.0.0.0:2300'" do
    expect(config.base_url).to eq URI("http://0.0.0.0:2300")
  end

  it "can be changed to another URI via a string" do
    expect { config.base_url = "http://example.com" }
      .to change { config.base_url }
      .to(URI("http://example.com"))
  end

  it "can be changed to another URI object" do
    expect { config.base_url = URI("http://example.com") }
      .to change { config.base_url }
      .to(URI("http://example.com"))
  end
end
