# frozen_string_literal: true

RSpec.describe "App action / CSRF protection", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end

    Hanami.app.instance_eval(&app_hook) if respond_to?(:app_hook)
    Hanami.app.register_slice :main
    Hanami.app.prepare

    module TestApp
      class Action < Hanami::Action
      end
    end
  end

  subject(:action_class) { TestApp::Action }

  context "app sessions enabled" do
    context "CSRF protection not explicitly configured" do
      let(:app_hook) {
        proc do
          config.actions.sessions = :cookie, {secret: "abc123"}
        end
      }

      it "has CSRF protection enabled" do
        expect(action_class.ancestors).to include Hanami::Action::CSRFProtection
      end
    end

    context "CSRF protection explicitly disabled" do
      let(:app_hook) {
        proc do
          config.actions.sessions = :cookie, {secret: "abc123"}
          config.actions.csrf_protection = false
        end
      }

      it "does not have CSRF protection enabled" do
        expect(action_class.ancestors.map(&:to_s)).not_to include "Hanami::Action::CSRFProtection"
      end
    end
  end

  context "app sessions not enabled" do
    it "does not have CSRF protection enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include "Hanami::Action::CSRFProtection"
    end
  end
end
