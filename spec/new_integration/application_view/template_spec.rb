# frozen_string_literal: true

require "hanami/application/view"

RSpec.describe "Application view / Template", :application_integration do
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

  subject(:template) { view_class.config.template }

  context "Ordinary slice view" do
    before do
      module Main
        module Views
          module Article
            class Index < View::Base
            end
          end
        end
      end
    end

    let(:view_class) { Main::Views::Article::Index }

    it "configures the tempalte to match the class name" do
      expect(template).to eq "article/index"
    end
  end

  context "Slice view with namespace matching template inference base" do
    before do
      module Main
        module MyViews
          module Users
            class Show < View::Base
            end
          end
        end
      end
    end

    let(:application_hook) {
      proc do
        config.views.template_inference_base = "my_views"
      end
    }

    let(:view_class) { Main::MyViews::Users::Show }

    it "configures the tempalte to match the class name" do
      expect(template).to eq "users/show"
    end
  end
end
