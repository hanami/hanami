# frozen_string_literal: true

require "hanami/configuration"
require "hanami/configuration/router"

RSpec.describe Hanami::Configuration, "#router" do
  let(:configuration) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:router) { configuration.router }

  context "hanami-router is bundled" do
    it "is a full router configuration" do
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

  context "hanami-router is not bundled" do
    before do
      allow(Hanami).to receive(:bundled?).and_call_original
      expect(Hanami).to receive(:bundled?).with("hanami-router").and_return(false)
    end

    it "does not expose any settings" do
      is_expected.not_to be_an_instance_of(Hanami::Configuration::Router)
      is_expected.not_to respond_to(:resolver)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
