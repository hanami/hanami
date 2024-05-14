# frozen_string_literal: true

RSpec.describe "Container / Provider environment", :app_integration do
  let!(:app) {
    module TestApp
      class App < Hanami::App
        class << self
          attr_accessor :test_provider_target
        end
      end
    end

    before_prepare if respond_to?(:before_prepare)

    Hanami.app.prepare
    Hanami.app
  }

  context "app provider" do
    before do
      Hanami.app.register_provider :test_provider, namespace: true do
        start do
          Hanami.app.test_provider_target = target
        end
      end
    end

    it "exposes the app as the provider target" do
      Hanami.app.start :test_provider
      expect(Hanami.app.test_provider_target).to be Hanami.app
    end
  end

  context "slice provider" do
    def before_prepare
      Hanami.app.register_slice :main
    end

    before do
      Main::Slice.register_provider :test_provider, namespace: true do
        start do
          Hanami.app.test_provider_target = target
        end
      end
    end

    it "exposes the slice as the provider target" do
      Main::Slice.start :test_provider
      expect(Hanami.app.test_provider_target).to be Main::Slice
    end
  end
end
