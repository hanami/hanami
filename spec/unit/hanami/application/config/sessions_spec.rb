# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.sessions" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.sessions

      expect(subject).to be_kind_of(Hanami::Configuration::Sessions)
      expect(subject.enabled?).to be(false)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.sessions = :cookie, { secret: "psst" }
      end
      subject = app.config.sessions

      expect(subject).to be_kind_of(Hanami::Configuration::Sessions)
      expect(subject.enabled?).to be(true)
      expect(subject.storage).to eq(:cookie)
      expect(subject.options).to eq(secret: "psst")
    end
  end
end
