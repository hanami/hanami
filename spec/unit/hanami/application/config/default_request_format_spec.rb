# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.default_request_format" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.default_request_format

      expect(subject).to eq(:html)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.default_request_format = :json
      end
      subject = app.config.default_request_format

      expect(subject).to eq(:json)
    end
  end
end
