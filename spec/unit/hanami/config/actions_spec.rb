# frozen_string_literal: true

require "hanami/config"
require "hanami/action"

RSpec.describe Hanami::Config, "#actions" do
  let(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:actions) { config.actions }

  context "hanami-controller is bundled" do
    it "is a full actions config" do
      is_expected.to be_an_instance_of(Hanami::Config::Actions)

      is_expected.to respond_to(:format)
    end

    it "configures base action settings" do
      expect { actions.public_directory = "pub" }
        .to change { actions.public_directory }
        .to end_with("pub")
    end

    it "configures base actions settings using custom methods" do
      expect { actions.formats.add(:json, "app/json") }
        .to change { actions.formats.mapping }
        .to include("app/json" => :json)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end

  context "hanami-controller is not bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      expect(Hanami).to receive(:bundled?).with("hanami-controller").and_return(false)
    end

    it "does not expose any settings" do
      is_expected.to be_an_instance_of(Hanami::Config::NullConfig)
      is_expected.not_to respond_to(:default_response_format)
      is_expected.not_to respond_to(:default_response_format=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
