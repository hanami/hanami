# frozen_string_literal: true

RSpec.describe "App action / Sessions", :app_integration do
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

  context "HTTP sessions enabled" do
    let(:app_hook) {
      proc do
        config.actions.sessions = :cookie, {secret: "abc123"}
      end
    }

    it "has HTTP sessions enabled" do
      expect(action_class.ancestors).to include(Hanami::Action::Session)
    end
  end

  context "HTTP sessions explicitly disabled" do
    let(:app_hook) {
      proc do
        config.actions.sessions = nil
      end
    }

    it "does not have HTTP sessions enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include("Hanami::Action::Session")
    end
  end

  context "HTTP sessions not enabled" do
    it "does not have HTTP session enabled" do
      expect(action_class.ancestors.map(&:to_s)).not_to include("Hanami::Action::Session")
    end
  end
end
