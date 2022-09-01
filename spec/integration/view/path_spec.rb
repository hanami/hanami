# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Path", :app_integration do
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

  subject(:paths) { view_class.config.paths }

  context "default path" do
    it "is 'templates' appended to the slice's root path" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/test_app/app/templates"]
    end
  end

  context "relative path provided in app config" do
    let(:app_hook) {
      proc do
        config.views.paths = ["my_templates"]
      end
    }

    it "configures the path as the relative path appended to the slice's root path" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/test_app/app/my_templates"]
    end
  end

  context "absolute path provided in app config" do
    let(:app_hook) {
      proc do
        config.views.paths = ["/absolute/path"]
      end
    }

    it "leaves the absolute path in place" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/absolute/path"]
    end
  end
end
