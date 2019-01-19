# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.inflections" do
    it "returns default" do
      app = Class.new(described_class)
      expect(app.config.inflections).to be_kind_of(Dry::Inflector)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.inflections do |i|
          i.uncountable("hanami")
        end
      end

      expect(app.config.inflections).to be_kind_of(Dry::Inflector)
      expect(app.config.inflections.pluralize("hanami")).to eq("hanami")
    end
  end
end
