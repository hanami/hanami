# frozen_string_literal: true

require "dry/system"
require "hanami/providers/db"

RSpec.describe "Hanami::Providers::DB / Config / Default config", :app_integration do
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

  def gateway_for(database_url, **connection_options)
    Hanami::Providers::DB::Gateway.new.tap do |gateway|
      gateway.config.database_url = database_url
      gateway.connection_options(**connection_options)
    end
  end

  specify %(relations_path = "relations") do
    expect(config)
  end

  describe "sql adapter" do
    before do
      skip_defaults if respond_to?(:skip_defaults)
      config.adapter(:sql).configure_for_gateway(gateway_for("mysql://localhost/test_app_development"))
    end

    describe "plugins" do
      specify do
        expect(config.adapter(:sql).plugins).to match [
          [{relations: :instrumentation}, instance_of(Proc)],
          [{relations: :auto_restrictions}, nil]
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

    describe "connect_sqls" do
      it "configures no connect_sqls for a non-SQLite database" do
        expect(config.adapter(:sql).connect_sqls).to eq []
      end

      it "leaves connect_sqls out of gateway_options" do
        expect(config.adapter(:sql).gateway_options).not_to have_key(:connect_sqls)
      end
    end
  end

  describe "sql adapter for postgres" do
    before do
      config.adapter(:sql).configure_for_gateway(gateway_for("postgresql://localhost/test_app_development"))
    end

    specify "extensions" do
      expect(config.adapters[:sql].extensions).to eq [
        :caller_logging,
        :error_sql,
        :sql_comments,
        :pg_array,
        :pg_enum,
        :pg_json,
        :pg_range
      ]
    end
  end

  describe "sql adapter for sqlite" do
    let(:database_url) { "sqlite://db/app.sqlite3" }
    let(:connection_options) { {} }

    before do
      skip_defaults if respond_to?(:skip_defaults)
      config.adapter(:sql).configure_for_gateway(gateway_for(database_url, **connection_options))
    end

    describe "connect_sqls" do
      it "configures the SQLite pragma defaults" do
        expect(config.adapter(:sql).connect_sqls).to eq Hanami::DB::SQLite::Pragmas.new.connect_sqls
      end

      context "with a single-colon sqlite URL" do
        let(:database_url) { "sqlite:db/app.sqlite3" }

        it "configures the SQLite pragma defaults" do
          expect(config.adapter(:sql).connect_sqls).to eq Hanami::DB::SQLite::Pragmas.new.connect_sqls
        end
      end

      context "with a jdbc:sqlite URL" do
        let(:database_url) { "jdbc:sqlite:db/app.sqlite3" }

        it "configures the SQLite pragma defaults" do
          expect(config.adapter(:sql).connect_sqls).to eq Hanami::DB::SQLite::Pragmas.new.connect_sqls
        end
      end

      context "with a read-only connection" do
        let(:connection_options) { {readonly: true} }

        it "configures the SQLite pragma defaults for read-only connections" do
          expect(config.adapter(:sql).connect_sqls).to eq Hanami::DB::SQLite::Pragmas.new(readonly: true).connect_sqls
          expect(config.adapter(:sql).connect_sqls).not_to include(a_string_matching(/journal_mode/))
        end
      end

      context "when configured more than once" do
        it "does not repeat the pragmas" do
          config.adapter(:sql).configure_for_gateway(gateway_for(database_url))

          expect(config.adapter(:sql).connect_sqls).to eq Hanami::DB::SQLite::Pragmas.new.connect_sqls
        end
      end

      describe "skipping defaults" do
        def skip_defaults
          config.adapter(:sql).skip_defaults :connect_sqls
        end

        it "configures no connect_sqls" do
          expect(config.adapter(:sql).connect_sqls).to eq []
        end
      end

      describe "skipping all defaults" do
        def skip_defaults
          config.adapter(:sql).skip_defaults
        end

        it "configures no connect_sqls" do
          expect(config.adapter(:sql).connect_sqls).to eq []
        end
      end
    end

    specify "gateway_options" do
      expect(config.adapter(:sql).gateway_options)
        .to include(connect_sqls: Hanami::DB::SQLite::Pragmas.new.connect_sqls)
    end
  end
end
