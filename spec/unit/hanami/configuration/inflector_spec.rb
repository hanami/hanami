# frozen_string_literal: true

require "hanami/configuration"

RSpec.describe Hanami::Configuration do
  subject(:config) { described_class.new(application_name: application_name, env: :development) }
  let(:application_name) { "MyApp::Application" }

  describe "inflector" do
    it "defaults to a Dry::Inflector instance" do
      expect(config.inflector).to be_kind_of(Dry::Inflector)
    end

    it "can be replaced with another inflector" do
      new_inflector = double(:inflector)

      expect { config.inflector = new_inflector }
        .to change { config.inflector }
        .to new_inflector
    end
  end

  describe "inflections" do
    it "configures a new inflector with the given inflections" do
      expect(config.inflector.pluralize("hanami")).to eq("hanamis")

      config.inflections do |i|
        i.uncountable("hanami")
      end

      expect(config.inflector).to be_kind_of(Dry::Inflector)
      expect(config.inflector.pluralize("hanami")).to eq("hanami")
    end
  end
end
