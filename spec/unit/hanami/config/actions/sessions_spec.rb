# frozen_string_literal: true

require "hanami/config/actions"

RSpec.describe Hanami::Config::Actions, "#sessions" do
  let(:config) { described_class.new }
  subject(:sessions) { config.sessions }

  context "no session config specified" do
    it "is not enabled" do
      expect(sessions).not_to be_enabled
    end

    it "returns nil storage" do
      expect(sessions.storage).to be_nil
    end

    it "returns empty options" do
      expect(sessions.options).to eq []
    end

    it "returns no session middleware" do
      expect(sessions.middleware).to eq []
    end
  end

  context "valid session config provided" do
    before do
      config.sessions = :cookie, {secret: "abc"}
    end

    it "is enabled" do
      expect(sessions).to be_enabled
    end

    it "returns the given storage" do
      expect(sessions.storage).to eq :cookie
    end

    it "returns the given options" do
      expect(sessions.options).to eq [secret: "abc"]
    end

    it "returns an array of middleware classes and options" do
      expect(sessions.middleware).to eq [Rack::Session::Cookie, {secret: "abc"}]
    end
  end
end
