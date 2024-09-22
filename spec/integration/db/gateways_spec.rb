# frozen_string_literal: true

RSpec.describe "DB / Gateways", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "configures gateways by detecting ENV vars" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "db/.keep", ""
      write "app/relations/.keep", ""
      write "slices/admin/relations/.keep", ""

      ENV["DATABASE_URL"] = "sqlite://db/default.sqlite3"
      ENV["DATABASE_URL__EXTRA"] = "sqlite://db/extra.sqlite3"
      ENV["ADMIN__DATABASE_URL__DEFAULT"] = "sqlite://db/admin.sqlite3"
      ENV["ADMIN__DATABASE_URL__SPECIAL"] = "sqlite://db/admin_special.sqlite3"

      require "hanami/prepare"

      expect(Hanami.app["db.rom"].gateways[:default]).to be
      expect(Hanami.app["db.rom"].gateways[:extra]).to be
      expect(Hanami.app["db.gateway"]).to be Hanami.app["db.rom"].gateways[:default]
      expect(Hanami.app["db.gateways.default"]).to be Hanami.app["db.rom"].gateways[:default]
      expect(Hanami.app["db.gateways.extra"]).to be Hanami.app["db.rom"].gateways[:extra]

      expect(Admin::Slice["db.rom"].gateways[:default]).to be
      expect(Admin::Slice["db.rom"].gateways[:special]).to be
      expect(Admin::Slice["db.gateway"]).to be Admin::Slice["db.rom"].gateways[:default]
      expect(Admin::Slice["db.gateways.default"]).to be Admin::Slice["db.rom"].gateways[:default]
      expect(Admin::Slice["db.gateways.special"]).to be Admin::Slice["db.rom"].gateways[:special]
    end
  end

  it "configures gateways from explicit config in the provider" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "db/.keep", ""

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.gateway :default do |gw|
            gw.database_url = "sqlite://db/default.sqlite3"
          end

          config.gateway :extra do |gw|
            gw.database_url = "sqlite://db/extra.sqlite3"
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app["db.rom"].gateways[:default]).to be
      expect(Hanami.app["db.rom"].gateways[:extra]).to be
      expect(Hanami.app["db.gateway"]).to be Hanami.app["db.rom"].gateways[:default]
      expect(Hanami.app["db.gateways.default"]).to be Hanami.app["db.rom"].gateways[:default]
      expect(Hanami.app["db.gateways.extra"]).to be Hanami.app["db.rom"].gateways[:extra]
    end
  end



  it "exposes all database URLs as #database_urls on the provider source (for CLI commands)" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.gateway :special do |gw|
            gw.database_url = "sqlite://db/special.sqlite3"
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://db/default.sqlite3"
      ENV["DATABASE_URL__EXTRA"] = "sqlite://db/extra.sqlite3"

      require "hanami/prepare"

      database_urls = Hanami.app.container.providers[:db].source.finalize_config.database_urls

      expect(database_urls).to eq(
        default: "sqlite://db/default.sqlite3",
        extra: "sqlite://db/extra.sqlite3",
        special: "sqlite://db/special.sqlite3"
      )
    end
  end

  it "applies extensions from the default adapter to explicitly configured gateway adapters" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.adapter :sql do |a|
            a.extension :is_distinct_from
          end

          config.gateway :default do |gw|
            gw.adapter :sql do |a|
              a.extension :exclude_or_null
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"
      ENV["DATABASE_URL__SPECIAL"] = "sqlite::memory"

      require "hanami/prepare"

      expect(Hanami.app["db.gateways.default"].options[:extensions])
        .to eq [:exclude_or_null, :is_distinct_from, :caller_logging, :error_sql, :sql_comments]

      expect(Hanami.app["db.gateways.special"].options[:extensions])
        .to eq [:is_distinct_from, :caller_logging, :error_sql, :sql_comments]
    end
  end

  it "combines ROM plugins from the default adapter and all gateways" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.adapter :sql do |a|
            a.plugin command: :associates
          end

          config.gateway :default do |gw|
            gw.database_url = "sqlite::memory"
            gw.adapter :sql do |a|
              a.plugin relation: :nullify
            end
          end

          config.gateway :special do |gw|
            gw.adapter :sql do |a|
              a.plugin relation: :pagination
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"
      ENV["DATABASE_URL__SPECIAL"] = "sqlite::memory"

      require "hanami/prepare"

      expect(Hanami.app["db.config"].setup.plugins.length).to eq 5
      expect(Hanami.app["db.config"].setup.plugins).to include(
        satisfying { |plugin| plugin.type == :command && plugin.name == :associates },
        satisfying { |plugin| plugin.type == :relation && plugin.name == :nullify },
        satisfying { |plugin| plugin.type == :relation && plugin.name == :pagination },
        satisfying { |plugin| plugin.type == :relation && plugin.name == :auto_restrictions },
        satisfying { |plugin| plugin.type == :relation && plugin.name == :instrumentation }
      )
    end
  end

  it "configures gateway adapters for their specific database types" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.gateway :default do |gw|
            gw.database_url = "sqlite::memory"
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"
      ENV["DATABASE_URL__SPECIAL"] = "postgres://localhost/database"

      require "hanami/prepare"

      # Get the provider source and finalize config, because the tests here aren't set up to handle
      # connections to a running postgres database
      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("pg").and_return true
      provider_source = Hanami.app.container.providers[:db].source
      provider_source.finalize_config

      expect(provider_source.config.gateways[:default].config.adapter.extensions)
        .to eq [:caller_logging, :error_sql, :sql_comments]

      expect(provider_source.config.gateways[:special].config.adapter.extensions)
        .to eq [
          :caller_logging, :error_sql, :sql_comments,
          :pg_array, :pg_enum, :pg_json, :pg_range
        ]
    end
  end

  it "makes the gateways available to relations" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      write "app/relations/users.rb", <<~RUBY
        module TestApp
          module Relations
            class Users < Hanami::DB::Relation
              gateway :extra
              schema :users, infer: true
            end
          end
        end
      RUBY

      write "db/.keep", ""
      ENV["DATABASE_URL"] = "sqlite://db/default.sqlite3"
      ENV["DATABASE_URL__EXTRA"] = "sqlite://db/extra.sqlite3"

      require "hanami/prepare"

      Hanami.app.prepare :db

      # Manually run a migration and add a test record
      default_gateway = Hanami.app["db.gateways.default"]
      migration = default_gateway.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end
        end
      end
      migration.apply(default_gateway, :up)
      default_gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      extra_gateway = Hanami.app["db.gateways.extra"]
      migration = extra_gateway.migration do
        change do
          create_table :users do
            primary_key :id
            column :name, :text, null: false
          end
        end
      end
      migration.apply(extra_gateway, :up)
      extra_gateway.connection.execute("INSERT INTO users (name) VALUES ('Jane Doe')")

      Hanami.app.boot

      expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Hanami.app["relations.users"].to_a).to eq [{id: 1, name: "Jane Doe"}]
    end
  end
end
