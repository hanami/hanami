# frozen_string_literal: true

require "hanami/view/extensions/application_view"

RSpec.describe Hanami::View, "application view extension", :application_integration do
  describe ".[]" do
    before do
      module TestApp
        class Application < Hanami::Application
          config.views.base_path = "test_views"
          config.views.templates_path = "testing/templates"
          config.views.layouts_dir = "test_layouts"
          config.views.default_layout = "testing"
        end
      end

      module Main
      end

      Hanami.application.register_slice :main, namespace: Main, root: "/path/to/slice"
    end

    subject(:view) { described_class[:main] }

    it "retuns a Hanami::View" do
      expect(view.ancestors).to include(Hanami::View)
    end

    it "raises an error when an unknown slice name is provided" do
      expect { described_class[:fneep] }.to raise_error(/Unknown slice.+fneep/)
    end

    describe "config" do
      subject(:config) { view.config }

      context "direct subclass as an abstract or \"base\" view class" do
        it "sets 'paths' to the target's root and application's configured templates_path" do
          expect(config.paths.map { |path| path.dir.to_s }).to eq ["/path/to/slice/testing/templates"]
        end

        it "sets 'layouts_dir' to the application's configured layouts_dir" do
          expect(config.layouts_dir).to eq "test_layouts"
        end

        it "sets 'layout' to the application's configured default_layout" do
          expect(config.layout).to eq "testing"
        end

        it "does not set 'template'" do
          expect(config.template).to be_nil
        end
      end

      context "subclass of a base class" do
        before do
          module Main
            class View < Hanami::View[:main]
            end

            module TestViews
              module Articles
                class Index < Main::View
                end
              end
            end
          end
        end

        let(:view) { Main::TestViews::Articles::Index }

        it "sets 'template' based on the view's class name, relative to the application's configured views base_path" do
          expect(config.template).to eq "articles/index"
        end
      end
    end
  end
end
