# frozen_string_literal: true

RSpec.describe "App action / Cookies", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end

    Hanami.app.instance_eval(&app_hook) if respond_to?(:app_hook)
    Hanami.app.prepare

    module TestApp
      class Action < Hanami::Action
      end
    end
  end

  subject(:action_class) { TestApp::Action }

  context "default configuration" do
    it "has cookie support enabled" do
      expect(action_class.ancestors).to include Hanami::Action::Cookies
    end
  end

  context "custom cookie options given in app-level config" do
    subject(:app_hook) {
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

  context "cookies disabled in app-level config" do
    subject(:app_hook) {
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
