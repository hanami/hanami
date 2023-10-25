# frozen_string_literal: true

require "hanami"
require "hanami/settings"

RSpec.describe "App view / Context / Settings", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end

      class Settings < Hanami::Settings
      end
    end

    Hanami.prepare

    module TestApp
      module Views
        class Context < Hanami::View::Context
        end
      end
    end
  end

  let(:context_class) { TestApp::Views::Context }
  subject(:context) { context_class.new }

  describe "#settings" do
    it "is the app settings by default" do
      expect(context.settings).to be TestApp::App["settings"]
    end

    context "injected settings" do
      subject(:context) {
        context_class.new(settings: settings)
      }

      let(:settings) { double(:settings) }

      it "is the injected settings" do
        expect(context.settings).to be settings
      end
    end
  end
end
