# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/views"

RSpec.describe Hanami::Configuration, "#views" do
  let(:configuration) { described_class.new(env: :development) }
  subject(:actions) { configuration.views }

  it "returns an Hanami::Configuration::Views" do
    is_expected.to be_an_instance_of(Hanami::Configuration::Views)
  end
end

RSpec.describe Hanami::Configuration::Views do
  subject(:configuration) { described_class.new }

  context "Hanami::View available" do
    it "exposes Hanami::View settings" do
      expect(configuration).to respond_to(:paths)
      expect(configuration).to respond_to(:paths=)
    end
  end

  context "Hanami::View not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/view"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/view")
        .and_raise load_error
    end

    it "does not expose any settings" do
      expect(configuration).not_to respond_to(:paths)
      expect(configuration).not_to respond_to(:paths=)
    end
  end
end
