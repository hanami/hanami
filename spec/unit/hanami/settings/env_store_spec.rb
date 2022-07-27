# frozen_string_literal: true

require "hanami/settings/env_store"

RSpec.describe Hanami::Settings::EnvStore do
  it "defaults to using ENV as the store" do
    orig_env = ENV.to_h

    ENV["FOO"] = "bar"
    expect(described_class.new.fetch("FOO")).to eq "bar"

    ENV.replace(orig_env)
  end

  describe "#fetch" do
    it "fetches from ENV" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect(store.fetch("FOO")).to eq("bar")
    end

    it "capitalizes name" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect(store.fetch("foo")).to eq("bar")
    end

    it "coerces name to string" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect(store.fetch(:foo)).to eq("bar")
    end

    it "returns default when value is not found" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect(store.fetch("BAZ", "qux")).to eq("qux")
    end

    it "returns the block execution when value is not found" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect(store.fetch("BAZ") { "qux" }).to eq("qux") # rubocop:disable Style/RedundantFetchBlock
    end

    it "raises KeyError when value is not found and no default is given" do
      store = described_class.new(store: {"FOO" => "bar"})

      expect { store.fetch("BAZ") }.to raise_error(KeyError)
    end
  end
end
