# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/actions"
require "hanami/action/configuration"

RSpec.describe Hanami::Configuration, "#actions" do
  let(:configuration) { described_class.new(application_name: application_name, env: :development) }
  let(:application_name) { "MyApp::Application" }

  subject(:actions) { configuration.actions }

  context "Hanami::Action available" do
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

      expect { actions.format json: "application/json" }
        .to change { actions.formats }
        .to("application/json" => :json)
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
        expect(actions.settings).to include(Hanami::Action::Configuration.settings)
      end
    end
  end

  context "Hanami::Action not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/action"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with(anything)
        .and_call_original

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/action")
        .and_raise load_error
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
