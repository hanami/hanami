require "hanami"

RSpec.describe "App view / Context / Inflector", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
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

  describe "#inflector" do
    it "is the app inflector by default" do
      expect(context.inflector).to be TestApp::App.inflector
    end

    context "injected inflector" do
      subject(:context) {
        context_class.new(inflector: inflector)
      }

      let(:inflector) { double(:inflector) }

      it "is the injected inflector" do
        expect(context.inflector).to be inflector
      end
    end
  end
end
