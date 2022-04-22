# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Template", :application_integration do
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

  subject(:template) { view_class.config.template }

  context "Ordinary app view" do
    before do
      module TestApp
        module Views
          module Article
            class Index < TestApp::View
            end
          end
        end
      end
    end

    let(:view_class) { TestApp::Views::Article::Index }

    it "configures the tempalte to match the class name" do
      expect(template).to eq "article/index"
    end
  end

  context "Slice view with namespace matching template inference base" do
    before do
      module TestApp
        module MyViews
          module Users
            class Show < TestApp::View
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

    let(:view_class) { TestApp::MyViews::Users::Show }

    it "configures the tempalte to match the class name" do
      expect(template).to eq "users/show"
    end
  end
end
