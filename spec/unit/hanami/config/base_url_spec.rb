# frozen_string_literal: true

require "hanami/config"
require "uri"

RSpec.describe Hanami::Config, "base_url" do
  subject(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

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
