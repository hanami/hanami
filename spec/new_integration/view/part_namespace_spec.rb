# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Part namespace", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.root = "/test_app"
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.prepare

    # The parts module (or any related setup) must exist _before_ we subclass
    # Hanami::View, because the parts_namespace is configured at the time of
    # subclassing (which happens right below)
    parts_module! if respond_to?(:parts_module!)

    module TestApp
      class View < Hanami::View
      end
    end

    module TestApp
      module Views
        module Article
          class Index < TestApp::View
          end
        end
      end
    end
  end

  subject(:part_namespace) { view_class.config.part_namespace }

  let(:view_class) { TestApp::Views::Article::Index }

  context "default parts_path" do
    let(:parts_module!) do
      module TestApp
        module Views
          module Parts
          end
        end
      end
    end

    it "is View::Parts" do
      is_expected.to eq TestApp::Views::Parts
    end
  end

  context "custom parts_path configured" do
    let(:application_hook) {
      proc do
        config.views.parts_path = "views/custom_parts"
      end
    }

    context "parts module exists" do
      let(:parts_module!) do
        module TestApp
          module Views
            module CustomParts
            end
          end
        end
      end

      it "is the matching module within the slice" do
        is_expected.to eq TestApp::Views::CustomParts
      end
    end

    context "parts module exists, but needs requiring first" do
      let(:parts_module!) do
        allow_any_instance_of(Object).to receive(:require).and_call_original
        allow_any_instance_of(Object).to receive(:require).with("app/views/custom_parts") {
          module TestApp
            module Views
              module CustomParts
              end
            end
          end
          true
        }
      end

      xit "is the matching module within the slice" do
        is_expected.to eq TestApp::Views::CustomParts
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
