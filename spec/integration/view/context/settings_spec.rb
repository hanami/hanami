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
    it "is not accessible as a public method" do
      expect { context.settings }.to raise_error(NoMethodError, /private method/)
    end

    it "is not included in public methods" do
      expect(context.public_methods).not_to include(:settings)
    end
  end
end
