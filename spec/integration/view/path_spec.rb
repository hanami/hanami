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

  it "is 'templates' appended to the slice's root path" do
    expect(paths.map { |path| path.dir.to_s }).to eq ["/test_app/app/templates"]
  end

  context "custom path provided in app config" do
    let(:app_hook) {
      proc do
        config.views.paths = ["/custom/path"]
      end
    }

    it "is the custom path" do
      expect(paths.map { |path| path.dir.to_s }).to eq ["/custom/path"]
    end
  end
end
