# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.base_url" do
    it "returns default" do
      app = Class.new(described_class)

      expect(app.config.base_url).to be_kind_of(URI::HTTP)
      expect(app.config.base_url.scheme).to eq("http")
      expect(app.config.base_url.host).to eq("0.0.0.0")
      expect(app.config.base_url.port).to eq(2300)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.base_url = "https://hanamirb.org"
      end

      expect(app.config.base_url).to be_kind_of(URI::HTTPS)
      expect(app.config.base_url.scheme).to eq("https")
      expect(app.config.base_url.host).to eq("hanamirb.org")
      expect(app.config.base_url.port).to eq(443)
    end
  end
end
