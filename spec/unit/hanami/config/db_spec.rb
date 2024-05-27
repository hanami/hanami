# frozen_string_literal: true

require "hanami/config"

RSpec.describe Hanami::Config, "#db" do
  let(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::App" }

  subject(:db) { config.db }

  context "hanami-router is bundled" do
    it "is a full router configuration" do
      is_expected.to be_an_instance_of(Hanami::Config::DB)

      is_expected.to respond_to(:import_from_parent)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end

  context "hanami-db is not bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("hanami-db").and_return(false)
    end

    it "does not expose any settings" do
      is_expected.to be_an_instance_of(Hanami::Config::NullConfig)
      is_expected.not_to respond_to(:import_from_parent)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
