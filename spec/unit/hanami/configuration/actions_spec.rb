# frozen_string_literal: true

require "hanami/configuration"
require "hanami/action/application_configuration"

RSpec.describe Hanami::Configuration, "#actions" do
  let(:configuration) { described_class.new(env: :development) }
  subject(:actions) { configuration.actions }

  context "Hanami::Action available" do
    it "exposes Hanami::Action's application configuration" do
      is_expected.to be_an_instance_of(Hanami::Action::ApplicationConfiguration)

      is_expected.to respond_to(:default_response_format)
      is_expected.to respond_to(:default_response_format=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end

  context "Hanami::Action not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/action/application_configuration"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with(anything)
        .and_call_original

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/action/application_configuration")
        .and_raise load_error
    end

    it "does not expose any settings" do
      is_expected.not_to be_an_instance_of(Hanami::Action::ApplicationConfiguration)
      is_expected.not_to respond_to(:default_response_format)
      is_expected.not_to respond_to(:default_response_format=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
