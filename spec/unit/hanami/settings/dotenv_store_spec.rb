# frozen_string_literal: true

require "hanami/settings/dotenv_store"
require "dotenv"

RSpec.describe Hanami::Settings::DotenvStore do
  def mock_dotenv(store)
    dotenv = spy(:dotenv)
    allow(store).to receive(:require).and_call_original
    stub_const "Dotenv", dotenv
  end

  describe "#with_dotenv_loaded" do
    context "dotenv available and environment other than test" do
      it "requires and loads a range of dotenv files, specific to the current environment" do
        store = described_class.new(store: {}, hanami_env: :development)
        dotenv = mock_dotenv(store)

        store.with_dotenv_loaded

        expect(store).to have_received(:require).with("dotenv").ordered
        expect(dotenv).to have_received(:load).ordered.with(
          ".env.development.local",
          ".env.local",
          ".env.development",
          ".env"
        )
      end

      it "returns self" do
        store = described_class.new(store: {}, hanami_env: :development)

        expect(store.with_dotenv_loaded).to be(store)
      end
    end

    context "dotenv available and test environment" do
      it "does not load .env.local (which is intended for non-test settings only)" do
        store = described_class.new(store: {}, hanami_env: :test)
        dotenv = mock_dotenv(store)

        store.with_dotenv_loaded

        expect(store).to have_received(:require).with("dotenv").ordered
        expect(dotenv).to have_received(:load).ordered.with(
          ".env.test.local",
          ".env.test",
          ".env"
        )
      end

      it "returns self" do
        store = described_class.new(store: {}, hanami_env: :test)

        expect(store.with_dotenv_loaded).to be(store)
      end
    end

    context "dotenv unavailable" do
      let(:store) { described_class.new(store: {}) }

      before do
        allow(store).to receive(:require).with("dotenv").and_raise LoadError
      end

      it "attempts to require dotenv" do
        store.with_dotenv_loaded

        expect(store).to have_received(:require).with("dotenv")
      end

      it "gracefully ignores load errors" do
        expect { store.with_dotenv_loaded }.not_to raise_error
      end

      it "returns self" do
        expect(store.with_dotenv_loaded).to be(store)
      end
    end
  end

  describe "#fetch" do
    it "fetches from ENV" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect(store.fetch("FOO")).to eq("bar")
    end

    it "capitalizes name" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect(store.fetch("foo")).to eq("bar")
    end

    it "coerces name to string" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect(store.fetch(:foo)).to eq("bar")
    end

    it "returns default when value is not found" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect(store.fetch("BAZ", "qux")).to eq("qux")
    end

    it "returns the block execution when value is not found" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect(store.fetch("BAZ") { "qux" }).to eq("qux")
    end

    it "raises KeyError when value is not found and no default is given" do
      store = described_class.new(store: { "FOO" => "bar" })

      expect{ store.fetch("BAZ") }.to raise_error(KeyError)
    end
  end
end
