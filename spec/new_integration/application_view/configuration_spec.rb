# frozen_string_literal: true

require "hanami/application/view"

RSpec.describe "Application view / Configuration", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.root = "/test_app"
        config.views.paths = ["templates"]
        config.views.layouts_dir = "test_app_layouts"
        config.views.layout = "testing"

        register_slice :main
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.prepare

    module TestApp
      module View
        class Base < Hanami::Application::View
        end
      end
    end

    module Main
      module View
        class Base < TestApp::View::Base
        end
      end
    end
  end

  subject(:config) { view_class.config }

  describe "base slice view class" do
    let(:view_class) { Main::View::Base }

    describe "path" do
      context "relative path provided in application config" do
        let(:application_hook) {
          proc do
            config.views.paths = ["templates"]
          end
        }

        it "configures the path as the relative path appended onto the slice's root path" do
          expect(config.paths.map { |path| path.dir.to_s }).to eq ["/test_app/slices/main/templates"]
        end
      end

      context "absolute path provided in application config" do
        let(:application_hook) {
          proc do
            config.views.paths = ["/absolute/path"]
          end
        }

        it "leaves the absolute path in place" do
          expect(config.paths.map { |path| path.dir.to_s }).to eq ["/absolute/path"]
        end
      end
    end

    it "applies standard view configuration from the application" do
      aggregate_failures do
        expect(config.layouts_dir).to eq "test_app_layouts"
        expect(config.layout).to eq "testing"
      end
    end
  end

  describe "concrete view class" do
    before do
      module Main
        module Views
          module Articles
            class Index < Main::View::Base
            end
          end
        end
      end
    end

    let(:view_class) { Main::Views::Articles::Index }

    it "inherits the application-specific configuration from the base class" do
      aggregate_failures do
        expect(config.paths.map { |path| path.dir.to_s }).to eq ["/test_app/slices/main/templates"]
        expect(config.layouts_dir).to eq "test_app_layouts"
        expect(config.layout).to eq "testing"
      end
    end
  end
end
