# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Path", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.root = "/test_app"

        register_slice :main
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.prepare

    module TestApp
      class View < Hanami::View
      end
    end

    module Main
      class View < TestApp::View
      end
    end
  end

  let(:view_class) { Main::View }

  subject(:paths) { view_class.config.paths }

  context "default path" do
    it "is 'templates' appended to the slice's root path" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/test_app/slices/main/templates"]
    end
  end

  context "relative path provided in application config" do
    let(:application_hook) {
      proc do
        config.views.paths = ["my_templates"]
      end
    }

    it "configures the path as the relative path appended to the slice's root path" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/test_app/slices/main/my_templates"]
    end
  end

  context "absolute path provided in application config" do
    let(:application_hook) {
      proc do
        config.views.paths = ["/absolute/path"]
      end
    }

    it "leaves the absolute path in place" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/absolute/path"]
    end
  end
end
