# frozen_string_literal: true

RSpec.describe Hanami::Application do
  describe ".config.cookies" do
    it "returns default" do
      app = Class.new(described_class)
      subject = app.config.cookies

      expect(subject).to be_kind_of(Hanami::Configuration::Cookies)
      expect(subject.enabled?).to be(false)
    end

    it "returns set value" do
      app = Class.new(described_class) do
        config.cookies = { max_age: 300 }
      end
      subject = app.config.cookies

      expect(subject).to be_kind_of(Hanami::Configuration::Cookies)
      expect(subject.enabled?).to be(true)
      expect(subject.options).to eq(max_age: 300)
    end
  end
end
