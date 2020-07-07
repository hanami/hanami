# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/actions"

RSpec.describe Hanami::Configuration, "#actions" do
  let(:configuration) { described_class.new(env: :development) }
  subject(:actions) { configuration.actions }

  it "returns an Hanami::Configuration::Actions" do
    is_expected.to be_an_instance_of(Hanami::Configuration::Actions)
  end
end

RSpec.describe Hanami::Configuration::Actions do
  subject(:configuration) { described_class.new }

  context "Hanami::Action::Configuration available" do
    it "exposes Hanami::Action::Configuration settings" do
      expect(configuration).to respond_to(:default_response_format)
      expect(configuration).to respond_to(:default_response_format=)
    end
  end

  context "Hanami::Action::Configuration not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/action/configuration"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/action/configuration")
        .and_raise load_error
    end

    it "does not expose any settings" do
      expect(configuration).not_to respond_to(:default_response_format)
      expect(configuration).not_to respond_to(:default_response_format=)
    end
  end
end
