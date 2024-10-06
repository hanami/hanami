# frozen_string_literal: true

require "dry/system"
require "hanami/providers/db"

RSpec.describe "Hanami::Providers::DB / Config / Gateway config", :app_integration do
  subject(:config) { provider.source.config }

  let(:provider) {
    Hanami.app.prepare
    Hanami.app.configure_provider(:db)
    Hanami.app.container.providers[:db]
  }

  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  describe "sql adapter" do
    before do
      config.adapter(:sql).configure_for_database("sqlite::memory")
    end

    describe "connection_options" do
      let(:default) { config.gateway(:default) }

      it "merges kwargs into connection_options configuration" do
        expect { default.connection_options(timeout: 10_000) }
          .to change { default.connection_options }.from({}).to({timeout: 10_000})
      end

      it "sets options per-gateway" do
        other = config.gateway(:other)
        expect { default.connection_options(timeout: 10_000) }
          .to_not change { other.connection_options }
      end

      it "is reflected in Gateway#cache_keys" do
        default.adapter(:sql) {}
        expect { default.connection_options(timeout: 10_000) }
          .to change { default.cache_keys }
      end
    end

    describe "options" do
      it "combines connection_options with adapter.gateway_options" do
        config.gateway :default do |gw|
          gw.connection_options foo: "bar"

          gw.adapter :sql do |a|
            a.skip_defaults
            a.extension :baz, :quux
          end
        end

        expect(config.gateway(:default).options)
          .to include(foo: "bar", extensions: [:baz, :quux])
      end

      it "ignores conflicting keys from connection_options" do
        config.gateway :default do |gw|
          gw.connection_options extensions: "foo"
          gw.adapter(:sql) { _1.skip_defaults }
        end

        expect(config.gateway(:default).options).to eq({extensions: []})
      end
    end
  end
end
