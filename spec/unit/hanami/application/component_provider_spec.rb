# frozen_string_literal: true

require "hanami/application"

RSpec.describe Hanami::Application, "#component_provider", :application_integration do
  let(:application) { Hanami.application }

  before do
    module TestApp
      class Application < Hanami::Application
      end
    end

    module Main
    end

    application.register_slice :main, namespace: Main
  end

  context "component in slice namespace" do
    let(:component) { Main::Component = Class.new }

    it "returns the slice" do
      expect(application.component_provider(component)).to eq Main::Slice
    end
  end

  context "component in application namespace" do
    let(:component) { TestApp::Component = Class.new }

    it "returns the application" do
      expect(application.component_provider(component)).to eq application
    end
  end
end
