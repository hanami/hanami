# frozen_string_literal: true

require "dry/inflector"
require "hanami/config"
require "hanami/slice_name"

RSpec.describe Hanami::Config, "#slices" do
  subject(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { Hanami::SliceName.new(double(name: "MyApp::App"), inflector: Dry::Inflector.new) }

  subject(:slices) { config.slices }

  before do
    @orig_env = ENV.to_h
  end

  after do
    ENV.replace(@orig_env)
  end

  it "is nil by default" do
    is_expected.to be nil
  end

  it "defaults to the HANAMI_LOAD_SLICES env var, separated by commas" do
    ENV["HANAMI_SLICES"] = "main,admin"
    is_expected.to eq %w[main admin]
  end

  it "strips spaces from HANAMI_LOAD_SLICES env var entries" do
    ENV["HANAMI_SLICES"] = "main, admin"
    is_expected.to eq %w[main admin]
  end
end
