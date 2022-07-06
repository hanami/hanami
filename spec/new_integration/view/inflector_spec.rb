# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Inflector", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.root = "/test_app"
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.register_slice :main
    Hanami.application.prepare

    module TestApp
      class View < Hanami::View
      end
    end
  end

  subject(:view_class) { TestApp::View }

  context "default application inflector" do
    it "configures the view with the default application inflector" do
      expect(view_class.config.inflector).to be TestApp::Application.config.inflector
    end
  end

  context "custom inflections configured" do
    let(:application_hook) {
      proc do
        config.inflections do |inflections|
          inflections.acronym "NBA"
        end
      end
    }

    it "configures the view with the customized application inflector" do
      expect(view_class.config.inflector).to be TestApp::Application.config.inflector
      expect(view_class.config.inflector.camelize("nba_jam")).to eq "NBAJam"
    end
  end

  context "custom inflector configured on view class" do
    let(:custom_inflector) { Object.new }

    before do
      view_class.config.inflector = custom_inflector
    end

    it "overrides the default application inflector" do
      expect(view_class.config.inflector).to be custom_inflector
    end
  end
end
