# frozen_string_literal: true

require "hanami/config"

RSpec.describe Hanami::Config, "#router" do
  let(:config) { described_class.new(app_name: app_name, env: :development) }
  let(:app_name) { "MyApp::app" }

  subject(:router) { config.router }

  context "hanami-router is bundled" do
    it "is a full router configuration" do
      is_expected.to be_an_instance_of(Hanami::Config::Router)

      is_expected.to respond_to(:resolver)
    end

    it "loads the middleware stack" do
      subject

      expect(config.middleware_stack).not_to be_nil
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
      is_expected.to be_an_instance_of(Hanami::Config::NullConfig)
      is_expected.not_to respond_to(:resolver)
    end

    it "can be finalized" do
      is_expected.to respond_to(:finalize!)
    end
  end
end
