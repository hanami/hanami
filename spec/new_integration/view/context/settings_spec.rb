# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Context / Settings", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
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
    it "is the application settings by default" do
      expect(context.settings).to be TestApp::Application.settings
    end

    context "injected settings" do
      subject(:context) {
        context_class.new(settings: settings)
      }

      let(:settings) { double(:settings) }

      it "is the injected settings" do
        expect(context.settings).to be settings
      end

      context "rebuilt context" do
        subject(:new_context) { context.with }

        it "retains the injected settings" do
          expect(new_context.settings).to be settings
        end
      end
    end
  end
end
