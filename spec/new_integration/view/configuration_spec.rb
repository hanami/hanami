# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Configuration", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
        config.root = "/test_app"
      end
    end

    Hanami.app.instance_eval(&app_hook) if respond_to?(:app_hook)
    Hanami.app.register_slice :main
    Hanami.app.prepare

    module TestApp
      class View < Hanami::View
      end
    end
  end

  let(:view_class) { TestApp::View }

  subject(:config) { view_class.config }

  it "applies default view configuration from the app" do
    aggregate_failures do
      expect(config.layouts_dir).to eq "layouts"
      expect(config.layout).to eq "app"
    end
  end

  context "custom views configuration on app" do
    let(:app_hook) {
      proc do
        config.views.layouts_dir = "custom_layouts"
        config.views.layout = "my_layout"
      end
    }

    it "applies the custom configuration" do
      aggregate_failures do
        expect(config.layouts_dir).to eq "custom_layouts"
        expect(config.layout).to eq "my_layout"
      end
    end
  end
end
