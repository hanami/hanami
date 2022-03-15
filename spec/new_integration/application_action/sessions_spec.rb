# frozen_string_literal: true

require "hanami/application/action"

RSpec.describe "Application action / Sessions", :application_integration do
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

  context "HTTP sessions enabled" do
    let(:application_hook) {
      proc do
        config.actions.sessions = :cookie, {secret: "abc123"}
      end
    }

    it "has HTTP sessions enabled" do
      expect(action_class.ancestors).to include(Hanami::Action::Session)
    end
  end

  context "HTTP sessions explicitly disabled" do
    let(:application_hook) {
      proc do
        config.actions.sessions = nil
      end
    }

    it "does not have HTTP sessions enabled" do
      expect(action_class.ancestors).not_to include(Hanami::Action::Session)
    end
  end

  context "HTTP sessions not enabled" do
    it "does not have HTTP session enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include("Hanami::Action::Session")
    end
  end
end
