# frozen_string_literal: true

require "hanami/application/settings/loader"

RSpec.describe Hanami::Application::Settings::Loader do
  subject(:loader) { described_class.new }

  def build_config(&block)
    Class.new do
      include Dry::Configurable
    end.tap { |klass| klass.instance_eval(&block) if block_given? }.new.config
  end

  describe "#load" do
    subject(:loaded_settings) { loader.load(config, store).to_h }

    context "when no settings are defined" do
      it "returns config untouched" do
        config = build_config
        store = {}.freeze

        expect(loader.load(config, store)).to be(config)
      end
    end

    context "when settings are defined" do
      it "uses values from the store when present" do
        config = build_config do
          setting :database_url, "postgres://localhost/test_app_development"
        end
        store = { database_url: "mysql://localhost/test_app_development" }.freeze

        loader.load(config, store)

        expect(config.database_url).to eq("mysql://localhost/test_app_development")
      end

      it "uses defaults when values are not present in the store" do
        config = build_config do
          setting :database_url, "postgres://localhost/test_app_development"
        end
        store = {}.freeze

        loader.load(config, store)

        expect(config.database_url).to eq("postgres://localhost/test_app_development")
      end

      it "collects error for all failed settings" do
        config = build_config do
          setting :database_url, constructor: ->(_v) { raise "nope to database" }
          setting :redis_url, constructor: ->(_v) { raise "nope to redis" }
        end
        store = {
          database_url: "postgres://localhost/test_app_development",
          redis_url: "redis://localhost:6379"
        }.freeze

        expect { loader.load(config, store) }.to raise_error(
          described_class::InvalidSettingsError,
          /(database_url: nope to database).*(redis_url: nope to redis)/m,
        )
      end
    end
  end
end
