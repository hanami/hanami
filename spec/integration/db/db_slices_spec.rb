# frozen_string_literal: true

RSpec.describe "DB / Slices", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "slices using the same database_url and extensions share a gateway/connection" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      expect(Admin::Slice["db.rom"].gateways[:default]).to be Main::Slice["db.rom"].gateways[:default]
    end
  end

  specify "slices using a parent gateway with connection options share a gateway/connection" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.gateway :default do |gw|
            gw.connection_options timeout: 10_000
          end

          config.gateway :extra do |gw|
            gw.connection_options timeout: 20_000
          end
        end
      RUBY

      write "slices/main/config/providers/db.rb", <<~RUBY
        Main::Slice.configure_provider :db do
          config.gateway :bonus do |gw|
            gw.connection_options timeout: 5_000
          end
        end
      RUBY

      write "db/.keep", ""
      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("app.sqlite").to_s
      ENV["DATABASE_URL__EXTRA"] = "sqlite://" + Pathname(@dir).realpath.join("extra.sqlite").to_s
      ENV["DATABASE_URL__BONUS"] = "sqlite://" + Pathname(@dir).realpath.join("bonus.sqlite").to_s

      # "extra" gateway in admin slice, same URL as app
      ENV["ADMIN__DATABASE_URL__EXTRA"] = ENV["DATABASE_URL__EXTRA"]
      # "extra" gatway in main slice, different URL
      ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://" + Pathname(@dir).realpath.join("extra-main.sqlite").to_s
      # "bonus" gateway in admin slice, same URL as app
      ENV["ADMIN__DATABASE_URL__BONUS"] = ENV["DATABASE_URL__BONUS"]
      # "bonus" gateway in main slice, same URL as app; different connection options in provider
      ENV["MAIN__DATABASE_URL__BONUS"] = ENV["DATABASE_URL__BONUS"]

      require "hanami/prepare"

      expect(Admin::Slice["db.gateway"]).to be Hanami.app["db.gateway"]

      expect(Admin::Slice["db.gateways.extra"]).to be Hanami.app["db.gateways.extra"]
      expect(Main::Slice["db.gateways.extra"]).not_to be Hanami.app["db.gateways.extra"]

      expect(Admin::Slice["db.gateways.bonus"]).to be Hanami.app["db.gateways.bonus"]
      expect(Main::Slice["db.gateways.bonus"]).not_to be Hanami.app["db.gateways.bonus"]
    end
  end

  specify "slices using the same database_url but different extensions have distinct gateways/connections" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "slices/admin/config/providers/db.rb", <<~RUBY
        Admin::Slice.configure_provider :db do
          config.adapter :sql do |a|
            a.extensions.clear
          end
        end
      RUBY

      write "slices/main/config/providers/db.rb", <<~RUBY
        Main::Slice.configure_provider :db do
          config.adapter :sql do |a|
            a.extensions.clear
            a.extension :error_sql
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      # Different gateways, due to the distinct extensions
      expect(Admin::Slice["db.rom"].gateways[:default]).not_to be Main::Slice["db.rom"].gateways[:default]

      # Even though their URIs are the same
      expect(Admin::Slice["db.rom"].gateways[:default].connection.opts[:uri])
        .to eq Main::Slice["db.rom"].gateways[:default].connection.opts[:uri]
    end
  end

  specify "using separate relations per slice, while sharing config from the app" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.adapter :sql do |a|
            a.extension :exclude_or_null
          end
        end
      RUBY

      write "slices/admin/relations/posts.rb", <<~RUBY
        module Admin
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      write "slices/admin/relations/authors.rb", <<~RUBY
        module Admin
          module Relations
            class Authors < Hanami::DB::Relation
              schema :authors, infer: true
            end
          end
        end
      RUBY

      write "slices/main/config/providers/db.rb", <<~RUBY
        Main::Slice.configure_provider :db do
          config.adapter :sql do |a|
            a.skip_defaults :extensions
            a.extensions.clear
          end
        end
      RUBY

      write "slices/main/relations/posts.rb", <<~RUBY
        module Main
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("database.db").to_s

      # Extra gateway for app only. Unlike other config, not copied to child slices.
      ENV["DATABASE_URL__EXTRA"] = "sqlite://" + Pathname(@dir).realpath.join("extra.db").to_s

      require "hanami/prepare"

      Main::Slice.prepare :db

      expect(Main::Slice["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Main::Slice["db.gateway"]).to be_an_instance_of ROM::SQL::Gateway

      expect(Admin::Slice.registered?("db.config")).to be false

      Admin::Slice.prepare :db

      expect(Admin::Slice["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Admin::Slice["db.gateway"]).to be_an_instance_of ROM::SQL::Gateway

      # Manually run a migration and add a test record
      gateway = Admin::Slice["db.gateway"]
      migration = gateway.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end

          create_table :authors do
            primary_key :id
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      # Gateways on app are not passed down to child slices
      expect(Hanami.app["db.rom"].gateways.keys).to eq [:default, :extra]
      expect(Main::Slice["db.rom"].gateways.keys).to eq [:default]
      expect(Admin::Slice["db.rom"].gateways.keys).to eq [:default]

      # Admin slice has appropriate relations registered, and can access data
      expect(Admin::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Admin::Slice["relations.posts"]).to be Admin::Slice["db.rom"].relations[:posts]
      expect(Admin::Slice["relations.authors"]).to be Admin::Slice["db.rom"].relations[:authors]

      # Main slice can access data, and only has its own relations (no crossover from admin slice)
      expect(Main::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Main::Slice["relations.posts"]).to be Main::Slice["db.rom"].relations[:posts]
      expect(Main::Slice["db.rom"].relations.elements.keys).not_to include :authors
      expect(Main::Slice["relations.posts"]).not_to be Admin::Slice["relations.posts"]

      # Config in the app's db provider is copied to child slice providers
      expect(Admin::Slice["db.gateway"].options[:extensions]).to eq [
        :exclude_or_null,
        :caller_logging,
        :error_sql,
        :sql_comments
      ]
      # Except when it has been explicitly configured in a child slice provider
      expect(Main::Slice["db.gateway"].options[:extensions]).to eq []

      # Plugins configured in the app's db provider are copied to child slice providers
      expect(Admin::Slice["db.config"].setup.plugins.length).to eq 2
      expect(Admin::Slice["db.config"].setup.plugins).to include an_object_satisfying { |plugin|
        plugin.type == :relation && plugin.name == :auto_restrictions
      }
      expect(Admin::Slice["db.config"].setup.plugins).to include an_object_satisfying { |plugin|
        plugin.type == :relation && plugin.name == :instrumentation
      }

      expect(Main::Slice["db.config"].setup.plugins).to eq Admin::Slice["db.config"].setup.plugins
    end
  end

  specify "disabling sharing of config from the app" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.adapter :sql do |a|
            a.extension :exclude_or_null
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            config.db.configure_from_parent = false
          end
        end
      RUBY

      write "slices/admin/config/providers/db.rb", <<~RUBY
        Admin::Slice.configure_provider :db do
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("database.db").to_s

      require "hanami/prepare"

      expect(Admin::Slice["db.gateway"].options[:extensions]).not_to include :exclude_or_null
    end
  end

  specify "slices using separate databases" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "slices/admin/relations/posts.rb", <<~RUBY
        module Admin
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      write "slices/admin/slices/super/relations/posts.rb", <<~RUBY
        module Admin
          module Super
            module Relations
              class Posts < Hanami::DB::Relation
                schema :posts, infer: true
              end
            end
          end
        end
      RUBY

      write "slices/main/relations/posts.rb", <<~RUBY
        module Main
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["ADMIN__DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("admin.db").to_s
      ENV["ADMIN__SUPER__DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("admin_super.db").to_s
      ENV["MAIN__DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("main.db").to_s

      require "hanami/prepare"

      Admin::Slice.prepare :db
      Admin::Super::Slice.prepare :db
      Main::Slice.prepare :db

      # Manually run a migration and add a test record in each slice's database
      gateways = [
        Admin::Slice["db.gateway"],
        Admin::Super::Slice["db.gateway"],
        Main::Slice["db.gateway"]
      ]
      gateways.each do |gateway|
        migration = gateway.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end

            create_table :authors do
              primary_key :id
            end
          end
        end
        migration.apply(gateway, :up)
      end
      gateways[0].connection.execute("INSERT INTO posts (title) VALUES ('Gem glow')")
      gateways[1].connection.execute("INSERT INTO posts (title) VALUES ('Cheeseburger backpack')")
      gateways[2].connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      expect(Admin::Slice["relations.posts"].to_a).to eq [{id: 1, title: "Gem glow"}]
      expect(Admin::Super::Slice["relations.posts"].to_a).to eq [{id: 1, title: "Cheeseburger backpack"}]
      expect(Main::Slice["relations.posts"].to_a).to eq [{id: 1, title: "Together breakfast"}]
    end
  end
end
