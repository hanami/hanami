# frozen_string_literal: true

RSpec.describe "Application action / CSRF protection", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.register_slice :main
    Hanami.application.prepare

    module TestApp
      class Action < Hanami::Action
      end
    end
  end

  subject(:action_class) { TestApp::Action }

  context "application sessions enabled" do
    context "CSRF protection not explicitly configured" do
      let(:application_hook) {
        proc do
          config.actions.sessions = :cookie, {secret: "abc123"}
        end
      }

      it "has CSRF protection enabled" do
        expect(action_class.ancestors).to include Hanami::Action::CSRFProtection
      end
    end

    context "CSRF protection explicitly disabled" do
      let(:application_hook) {
        proc do
          config.sessions = :cookie, {secret: "abc123"}
          config.actions.csrf_protection = false
        end
      }

      it "does not have CSRF protection enabled" do
        expect(action_class.ancestors.map(&:to_s)).not_to include "Hanami::Action::CSRFProtection"
      end
    end
  end

  context "application sessions not enabled" do
    it "does not have CSRF protection enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include "Hanami::Action::CSRFProtection"
    end
  end
end
