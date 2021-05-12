# frozen_string_literal: true

require "hanami/configuration"
require "hanami/view/application_configuration"

RSpec.describe Hanami::Configuration, "#views" do
  let(:configuration) { described_class.new(env: :development) }
  subject(:views) { configuration.views }

  context "Hanami::View available" do
    it "exposes Hanami::Views's application configuration" do
      is_expected.to be_an_instance_of(Hanami::View::ApplicationConfiguration)

      is_expected.to respond_to(:finalize!)
      is_expected.to respond_to(:layouts_dir)
      is_expected.to respond_to(:layouts_dir=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end

  context "Hanami::View not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/view/application_configuration"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with(anything)
        .and_call_original

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/view/application_configuration")
        .and_raise load_error
    end

    it "does not expose any settings" do
      is_expected.not_to be_an_instance_of(Hanami::View::ApplicationConfiguration)
      is_expected.not_to respond_to(:layouts_dir)
      is_expected.not_to respond_to(:layouts_dir=)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
