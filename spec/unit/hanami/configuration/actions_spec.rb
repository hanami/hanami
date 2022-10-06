# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/actions"
require "hanami/action"

RSpec.describe Hanami::Configuration, "#actions" do
  let(:configuration) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:actions) { configuration.actions }

  context "hanami-controller is bundled" do
    it "is a full actions configuration" do
      is_expected.to be_an_instance_of(Hanami::Configuration::Actions)

      is_expected.to respond_to(:default_response_format)
      is_expected.to respond_to(:default_response_format=)
    end

    it "configures base action settings" do
      expect { actions.default_request_format = :json }
        .to change { actions.default_request_format }
        .to :json
    end

    it "configures base actions settings using custom methods" do
      actions.formats = {}

      expect { actions.format json: "app/json" }
        .to change { actions.formats }
        .to("app/json" => :json)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end

    describe "#settings" do
      it "returns a set of available settings" do
        expect(actions.settings).to be_a(Set)
        expect(actions.settings).to include(:view_context_identifier, :handled_exceptions)
      end

      it "includes all base action settings" do
        expect(actions.settings).to include(Hanami::Action.settings)
      end
    end
  end

  context "hanami-controller is not bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      expect(Hanami).to receive(:bundled?).with("hanami-controller").and_return(false)
    end

    it "does not expose any settings" do
      is_expected.not_to be_an_instance_of(Hanami::Configuration::Actions)
      is_expected.not_to respond_to(:default_response_format)
      is_expected.not_to respond_to(:default_response_format=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
