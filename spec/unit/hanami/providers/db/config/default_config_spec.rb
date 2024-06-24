# frozen_string_literal: true

require "dry/system"
require "hanami/providers/db"

RSpec.describe "Hanami::Providers::DB / Config / Default config", :app_integration do
  subject(:config) { provider.source.config }

  let(:provider) {
    Hanami.app.configure_provider(:db)
    Hanami.app.container.providers[:db]
  }

  before do
    module TestApp
      class App < Hanami::App
      end
    end
  end

  specify "database_url = nil" do
    expect(config.database_url).to be nil
  end

  specify "adapter = :sql" do
    expect(config.adapter).to eq :sql
  end

  specify %(relations_path = "relations") do
    expect(config)
  end

  describe "sql adapter" do
    before do
      skip_defaults if respond_to?(:skip_defaults)
      config.adapter(:sql).configure_for_database("mysql://localhost/test_app_development")
    end

    describe "plugins" do
      specify do
        expect(config.adapter(:sql).plugins).to match [
          [{relations: :instrumentation}, instance_of(Proc)]
        ]
      end

      describe "skipping defaults" do
        def skip_defaults
          config.adapter(:sql).skip_defaults :plugins
        end

        it "configures no plugins" do
          expect(config.adapter(:sql).plugins).to eq []
        end
      end
    end

    describe "extensions" do
      specify do
        expect(config.adapter(:sql).extensions).to eq [
          :caller_logging,
          :error_sql,
          :sql_comments
        ]
      end

      describe "skipping defaults" do
        def skip_defaults
          config.adapter(:sql).skip_defaults :extensions
        end

        it "configures no extensions" do
          expect(config.adapter(:sql).extensions).to eq []
        end
      end
    end

    describe "skipping all defaults" do
      def skip_defaults
        config.adapter(:sql).skip_defaults
      end

      it "configures no plugins or extensions" do
        expect(config.adapter(:sql).plugins).to eq []
        expect(config.adapter(:sql).extensions).to eq []
      end
    end
  end

  describe "sql adapter for postgres" do
    before do
      config.adapter(:sql).configure_for_database("postgresql://localhost/test_app_development")
    end

    specify "extensions" do
      expect(config.adapters[:sql].extensions).to eq [
        :caller_logging,
        :error_sql,
        :sql_comments,
        :pg_array,
        :pg_json,
        :pg_range
      ]
    end
  end
end
