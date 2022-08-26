# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/router"

RSpec.describe Hanami::Configuration, "#router" do
  let(:configuration) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:router) { configuration.router }

  context "Hanami::Router available" do
    it "exposes Hanami::Router's app configuration" do
      is_expected.to be_an_instance_of(Hanami::Configuration::Router)

      is_expected.to respond_to(:resolver)
    end

    it "loads the middleware stack" do
      subject

      expect(configuration.middleware_stack).not_to be_nil
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end

  context "Hanami::Router not available" do
    before do
      load_error = LoadError.new.tap do |error|
        error.instance_variable_set :@path, "hanami/router"
      end

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with(anything)
        .and_call_original

      allow_any_instance_of(described_class)
        .to receive(:require)
        .with("hanami/router")
        .and_raise load_error
    end

    it "raises an error" do
      expect { subject }.to raise_error(described_class::ComponentNotAvailable, "`hanami/router` is not available")
    end
  end
end
