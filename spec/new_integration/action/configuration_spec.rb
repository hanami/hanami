# frozen_string_literal: true

RSpec.describe "App action / Configuration", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
        config.actions.default_response_format = :json
        register_slice :main
      end
    end

    Hanami.app.prepare

    module TestApp
      class Action < Hanami::Action
      end
    end
  end

  let(:action_class) { TestApp::Action }
  subject(:configuration) { action_class.config }

  it "applies 'config.actions' configuration from the app" do
    expect(configuration.default_response_format).to eq :json
  end
end
