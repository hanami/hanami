# frozen_string_literal: true

require "hanami/application/view"

RSpec.describe "Application view / Part namespace", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.root = "/test_app"

        register_slice :main
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.prepare

    # The parts module (or any related setup) must exist _before_ we subclass
    # Hanami::Application::View, because the parts_namespace is configured at the time of
    # subclassing (which happens right below)
    parts_module! if respond_to?(:parts_module!)

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

      module Views
        module Article
          class Index < View::Base
          end
        end
      end
    end
  end

  subject(:part_namespace) { view_class.config.part_namespace }

  let(:view_class) { Main::Views::Article::Index }

  context "default parts_path" do
    let(:parts_module!) do
      module Main
        module View
          module Parts
          end
        end
      end
    end

    it "is View::Parts" do
      is_expected.to eq Main::View::Parts
    end
  end

  context "custom parts_path configured" do
    let(:application_hook) {
      proc do
        config.views.parts_path = "view/custom_parts"
      end
    }

    context "parts module exists" do
      let(:parts_module!) do
        module Main
          module View
            module CustomParts
            end
          end
        end
      end

      it "is the matching module within the slice" do
        is_expected.to eq Main::View::CustomParts
      end
    end

    context "parts module exists, but needs requiring first" do
      let(:parts_module!) do
        allow_any_instance_of(Object).to receive(:require).and_call_original
        allow_any_instance_of(Object).to receive(:require).with("main/view/custom_parts") {
          module Main
            module View
              module CustomParts
              end
            end
          end
          true
        }
      end

      it "is the matching module within the slice" do
        is_expected.to eq Main::View::CustomParts
      end
    end

    context "namespace does not exist" do
      it "is nil" do
        is_expected.to be_nil
      end
    end
  end

  context "nil parts_path configured" do
    let(:application_hook) {
      proc do
        config.views.parts_path = nil
      end
    }

    it "is nil" do
      is_expected.to be_nil
    end
  end
end
