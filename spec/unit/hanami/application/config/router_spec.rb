# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.router" do
    it "returns default" do
      app = Class.new(described_class)
      expect(app.config.router).to be_kind_of(Hanami::Configuration::Router)
    end

    it "returns set value" do
      router = double("router")
      app = Class.new(described_class) do
        config.router = router
      end

      expect(app.config.router).to eq(router)
    end
  end
end
