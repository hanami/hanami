# frozen_string_literal: true

require "hanami/application/settings/dotenv_store"
require "dotenv"

RSpec.describe Hanami::Application::Settings::DotenvStore do
  describe "#with_dotenv_loaded" do
    let(:store) { described_class.new }

    context "dotenv available" do
      let(:dotenv) { spy(:dotenv) }

      before do
        allow(store).to receive(:require).and_call_original
        stub_const "Dotenv", dotenv
      end

      it "requires and loads a range of dotenv files, specific to the current HANAMI_ENV" do
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
        expect(store.with_dotenv_loaded).to be(store)
      end

      context "HANAMI_ENV is 'test'" do
        before do
          @hanami_env = ENV["HANAMI_ENV"]
          ENV["HANAMI_ENV"] = "test"
        end

        after do
          ENV["HANAMI_ENV"] = @hanami_env
        end

        it "does not load .env.local (which is intended for non-test settings only)" do
          store.with_dotenv_loaded

          expect(dotenv).to have_received(:load).ordered.with(
            ".env.test.local",
            ".env.test",
            ".env"
          )
        end
      end

      context "dotenv unavailable" do
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
  end

  describe "#fetch" do
    let(:store) { described_class.new }

    before do
      ENV["FOO"] = "bar"
    end

    after do
      ENV.delete("FOO")
    end

    it "fetches from ENV" do
      expect(store.fetch("FOO")).to eq("bar")
    end

    it "capitalizes name" do
      expect(store.fetch("foo")).to eq("bar")
    end

    it "coerces name to string" do
      expect(store.fetch(:foo)).to eq("bar")
    end

    it "returns the block execution when value is not found" do
      expect(store.fetch("BAZ") { "qux" }).to eq("qux")
    end
  end
end
