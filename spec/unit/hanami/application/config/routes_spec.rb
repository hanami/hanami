# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.routes" do
    it "returns default" do
      app = Class.new(described_class)
      expect(app.config.routes).to eq("config/routes")
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.routes = "path/to/routes"
      end

      expect(app.config.routes).to eq("path/to/routes")
    end
  end
end
