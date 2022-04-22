# frozen_string_literal: true

require "hanami/application/action"

RSpec.describe "Application action / CSRF protection", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        register_slice :main
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
    Hanami.application.prepare

    module Main
      class Action < Hanami::Application::Action
      end
    end
  end

  subject(:action_class) { Main::Action }

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
