# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Config / Inflector", :app_integration do
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

  subject(:view_class) { TestApp::View }

  context "default app inflector" do
    it "configures the view with the default app inflector" do
      expect(view_class.config.inflector).to be TestApp::App.config.inflector
    end
  end

  context "custom inflections configured" do
    let(:app_hook) {
      proc do
        config.inflections do |inflections|
          inflections.acronym "NBA"
        end
      end
    }

    it "configures the view with the customized app inflector" do
      expect(view_class.config.inflector).to be TestApp::App.config.inflector
      expect(view_class.config.inflector.camelize("nba_jam")).to eq "NBAJam"
    end
  end

  context "custom inflector configured on view class" do
    let(:custom_inflector) { Object.new }

    before do
      view_class.config.inflector = custom_inflector
    end

    it "overrides the default app inflector" do
      expect(view_class.config.inflector).to be custom_inflector
    end
  end
end
