# frozen_string_literal: true

require "hanami/application"

RSpec.describe Hanami::Application, "#component_provider", :application_integration do
  let(:application) { Hanami.application }
  let(:application_modules) { %i[TestApp Main External] }

  before do
    module TestApp
      class Application < Hanami::Application
      end
    end

    application.register_slice :main

    Hanami.prepare
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

  context "component from external (non-app/slice) namespace" do
    before do
      module External; end
    end

    let(:component) { External::Component = Class.new }

    it "returns nil" do
      expect(application.component_provider(component)).to be_nil
    end
  end

  context "unnamed component" do
    let(:component) { Class.new }

    it "returns nil" do
      expect(application.component_provider(component)).to be_nil
    end
  end
end
