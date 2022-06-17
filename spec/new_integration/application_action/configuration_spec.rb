# frozen_string_literal: true

require "hanami/application/action"

RSpec.describe "Application action / Configuration", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        config.actions.default_response_format = :json
        register_slice :main
      end
    end

    Hanami.application.prepare

    module Main
      class Action < Hanami::Application::Action
      end
    end
  end

  let(:action_class) { Main::Action }
  subject(:configuration) { action_class.config }

  it "applies 'config.actions' configuration from the application" do
    expect(configuration.default_response_format).to eq :json
  end
end
