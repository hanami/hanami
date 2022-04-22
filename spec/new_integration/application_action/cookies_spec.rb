# frozen_string_literal: true

require "hanami/application/action"

RSpec.describe "Application action / Cookies", :application_integration do
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

  context "default configuration" do
    it "has cookie support enabled" do
      expect(action_class.ancestors).to include Hanami::Action::Cookies
    end
  end

  context "custom cookie options given in application-level config" do
    subject(:application_hook) {
      proc do
        config.actions.cookies = {max_age: 300}
      end
    }

    it "has cookie support enabled" do
      expect(action_class.ancestors).to include Hanami::Action::Cookies
    end

    it "has the cookie options configured" do
      expect(action_class.config.cookies).to eq(max_age: 300)
    end
  end

  context "cookies disabled in application-level config" do
    subject(:application_hook) {
      proc do
        config.actions.cookies = nil
      end
    }

    it "does not have cookie support enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include "Hanami::Action::Cookies"
    end

    it "has no cookie options configured" do
      expect(action_class.config.cookies).to eq({})
    end
  end
end
