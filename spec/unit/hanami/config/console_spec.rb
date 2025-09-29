# frozen_string_literal: true

require "hanami/config"

RSpec.describe Hanami::Config, "#console" do
  let(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::App" }

  subject(:console) { config.console }

  it "is a full console configuration" do
    is_expected.to be_an_instance_of(Hanami::Config::Console)

    is_expected.to respond_to(:engine)
    is_expected.to respond_to(:include)
    is_expected.to respond_to(:extensions)
  end

  it "can be finalized" do
    is_expected.to respond_to(:finalize!)
  end
end
