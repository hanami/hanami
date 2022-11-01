# frozen_string_literal: true

require "hanami/settings"

RSpec.describe Hanami::Settings do
  describe "#initialize" do
    it "uses values from the store when present" do
      settings_class = Class.new(described_class) do
        setting :database_url, default: "postgres://localhost/test_app_development"
      end

      store = {database_url: "mysql://localhost/test_app_development"}.freeze

      instance = settings_class.new(store)

      expect(instance.config.database_url).to eq("mysql://localhost/test_app_development")
    end

    it "uses defaults when values are not present in the store" do
      settings_class = Class.new(described_class) do
        setting :database_url, default: "postgres://localhost/test_app_development"
      end

      store = {}.freeze

      instance = settings_class.new(store)

      expect(instance.config.database_url).to eq("postgres://localhost/test_app_development")
    end

    it "collects error for all setting values failing their constructors" do
      settings_class = Class.new(described_class) do
        setting :database_url, constructor: ->(_v) { raise "nope to database" }
        setting :redis_url, constructor: ->(_v) { raise "nope to redis" }
      end

      store = {
        database_url: "postgres://localhost/test_app_development",
        redis_url: "redis://localhost:6379"
      }.freeze

      expect { settings_class.new(store) }.to raise_error(
        described_class::InvalidSettingsError,
        /(database_url: nope to database).*(redis_url: nope to redis)/m,
      )
    end

    it "collects errors for missing settings failing their constructors" do
      settings_class = Class.new(described_class) do
        setting :database_url, constructor: ->(_v) { raise "nope to database" }
      end

      store = {}

      expect { settings_class.new(store) }.to raise_error(
        described_class::InvalidSettingsError,
        /database_url: nope to database/m,
      )
    end

    it "finalizes the config" do
      settings_class = Class.new(described_class) do
        setting :database_url
      end

      store = {database_url: "postgres://localhost/test_app_development"}

      settings = settings_class.new(store)

      expect(settings.config).to be_frozen
      expect { settings.database_url = "new" }.to raise_error(Dry::Configurable::FrozenConfigError)
    end
  end

  describe "#inspect" do
    it "shows keys" do
      settings_class = Class.new(described_class) do
        setting :password, default: "dont_tell_anybody"
        setting :passphrase, default: "shhhh"
      end

      expect(settings_class.new.inspect).to eq(
        "#<#{settings_class.to_s} [password, passphrase]>"
      )
    end
  end

  describe "#inspect_values" do
    it "shows keys & values" do
      settings_class = Class.new(described_class) do
        setting :password, default: "dont_tell_anybody"
        setting :passphrase, default: "shhh"
      end

      expect(settings_class.new.inspect_values).to eq(
        "#<#{settings_class.to_s} password=\"dont_tell_anybody\" passphrase=\"shhh\">"
      )
    end
  end

  it "delegates unknown methods to config" do
    settings_class = Class.new(described_class) do
      setting :foo, default: "bar"
    end
    store = {}.freeze

    instance = settings_class.new(store)

    expect(instance.foo).to eq("bar")
  end
end
