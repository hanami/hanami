# frozen_string_literal: true

require "hanami/config/actions"

RSpec.describe Hanami::Config::Actions, "#cookies" do
  let(:config) { described_class.new }
  subject(:cookies) { config.cookies }

  context "default config" do
    it "is enabled" do
      expect(cookies).to be_enabled
    end

    it "is an empty hash" do
      expect(cookies.to_h).to eq({})
    end
  end

  context "options given" do
    before do
      config.cookies = {max_age: 300}
    end

    it "is enabled" do
      expect(cookies).to be_enabled
    end

    it "returns the given options" do
      expect(cookies.to_h).to eq(max_age: 300)
    end
  end

  context "nil value given" do
    before do
      config.cookies = nil
    end

    it "is not enabled" do
      expect(cookies).not_to be_enabled
    end

    it "returns an empty hash" do
      expect(cookies.to_h).to eq({})
    end
  end
end
