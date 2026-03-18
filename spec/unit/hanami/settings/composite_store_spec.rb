# frozen_string_literal: true

require "hanami/settings/composite_store"

RSpec.describe Hanami::Settings::CompositeStore do
  describe "#fetch" do
    it "returns the value from the first store that has it" do
      store1 = {"FOO" => "from_store1"}
      store2 = {"FOO" => "from_store2"}
      composite = described_class.new(store1, store2)

      expect(composite.fetch("FOO")).to eq("from_store1")
    end

    it "falls back to the next store when the first does not have the key" do
      store1 = {"BAR" => "only_in_store1"}
      store2 = {"FOO" => "from_store2"}
      composite = described_class.new(store1, store2)

      expect(composite.fetch("FOO")).to eq("from_store2")
    end

    it "works with more than two stores" do
      store1 = {}
      store2 = {}
      store3 = {"FOO" => "from_store3"}
      composite = described_class.new(store1, store2, store3)

      expect(composite.fetch("FOO")).to eq("from_store3")
    end

    it "returns the default value when no store has the key" do
      store1 = {}
      store2 = {}
      composite = described_class.new(store1, store2)

      expect(composite.fetch("MISSING", "default")).to eq("default")
    end

    it "yields to the block when no store has the key and no default is given" do
      store1 = {}
      store2 = {}
      composite = described_class.new(store1, store2)

      expect(composite.fetch("MISSING") { |name| "block_#{name}" }).to eq("block_MISSING")
    end

    it "raises KeyError when no store has the key and no default or block is given" do
      store1 = {}
      store2 = {}
      composite = described_class.new(store1, store2)

      expect { composite.fetch("MISSING") }.to raise_error(KeyError, /MISSING/)
    end

    it "prefers the default value over the block" do
      store1 = {}
      composite = described_class.new(store1)

      expect(composite.fetch("MISSING", "default") { "block" }).to eq("default")
    end

    it "does not query later stores once a value is found" do
      store1 = {"FOO" => "found"}
      store2 = double("store2")
      composite = described_class.new(store1, store2)

      expect(composite.fetch("FOO")).to eq("found")
    end

    it "works with a single store" do
      store = {"FOO" => "bar"}
      composite = described_class.new(store)

      expect(composite.fetch("FOO")).to eq("bar")
    end

    it "raises KeyError with no stores" do
      composite = described_class.new

      expect { composite.fetch("ANYTHING") }.to raise_error(KeyError)
    end
  end
end
