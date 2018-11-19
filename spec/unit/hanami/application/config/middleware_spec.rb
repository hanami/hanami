# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.middleware" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.middleware

      expect(subject).to be_kind_of(Hanami::Configuration::Middleware)
      expect(subject.each {}.count).to be(0)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.middleware.use ->(*) { [200, {}, ["OK"]] }
      end
      subject = app.config.middleware

      expect(subject).to be_kind_of(Hanami::Configuration::Middleware)
      expect(subject.each {}.count).to be(1)
    end
  end
end
