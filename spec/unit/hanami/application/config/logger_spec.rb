# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.logger" do
    it "returns default" do
      app = Class.new(described_class)
      expect(app.config.logger).to eq(level: :debug)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.logger = { level: :info, formatter: :json }
      end

      expect(app.config.logger).to eq(level: :info, formatter: :json)
    end
  end
end
