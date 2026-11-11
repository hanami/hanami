# frozen_string_literal: true

require "hanami/config/assets"

RSpec.describe Hanami::Config::Assets do
  subject(:config) { described_class.new }

  it "reads hanami-assets settings" do
    expect(config.path_prefix).to eq "/assets"
    expect(config.node_command).to eq "node"
    expect(config.subresource_integrity).to eq []
    expect(config.base_url).to be_a Hanami::Assets::BaseUrl
  end

  it "reads hanami-assets settings without method_missing" do
    expect(config).not_to receive(:method_missing)

    Hanami::Assets::Config.settings.each do |setting|
      config.public_send(setting.name)
    end
  end

  it "writes hanami-assets settings" do
    config.path_prefix = "/files"
    config.subresource_integrity = [:sha256]

    expect(config.path_prefix).to eq "/files"
    expect(config.subresource_integrity).to eq [:sha256]
  end

  it "keeps settings separate in a copy" do
    copy = config.dup
    copy.path_prefix = "/files"

    expect(copy.path_prefix).to eq "/files"
    expect(config.path_prefix).to eq "/assets"
  end

  it "reads and writes its own settings" do
    config.serve = true

    expect(config.serve).to be true
  end

  it "responds to the settings of both configs" do
    expect(config).to respond_to(:serve, :path_prefix, :base_url=)
    expect(config).not_to respond_to(:unknown_setting)
  end

  it "raises for an unknown setting" do
    expect { config.unknown_setting }.to raise_error(NoMethodError)
  end
end
