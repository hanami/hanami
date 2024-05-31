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

  specify "slices using the same database_url but different extensions have distinct gateways/connections" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/admin/config/providers/db.rb", <<~RUBY
        Admin::Slice.configure_provider :db do
          config.extensions = []
        end
      RUBY

      write "slices/main/config/providers/db.rb", <<~RUBY
        Main::Slice.configure_provider :db do
          config.extensions = [:error_sql]
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
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          after(:prepare) do
            @rom_config.plugin(:sql, relations: :auto_restrictions)
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

      # Admin slice has appropriate relations registered, and can access data
      expect(Admin::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Admin::Slice["relations.posts"]).to be Admin::Slice["db.rom"].relations[:posts]
      expect(Admin::Slice["relations.authors"]).to be Admin::Slice["db.rom"].relations[:authors]

      # Main slice can access data, and only has its own relations (no crossover from admin slice)
      expect(Main::Slice["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Main::Slice["relations.posts"]).to be Main::Slice["db.rom"].relations[:posts]
      expect(Main::Slice["db.rom"].relations.elements.keys).not_to include :authors
      expect(Main::Slice["relations.posts"]).not_to be Admin::Slice["relations.posts"]

      # Plugins configured in the app's db provider are copied to child slice providers
      expect(Admin::Slice["db.config"].setup.plugins.length).to eq 1
      expect(Admin::Slice["db.config"].setup.plugins).to include an_object_satisfying { |plugin|
        plugin.name == :auto_restrictions && plugin.type == :relation
      }
      expect(Admin::Slice["db.config"].setup.plugins).to eq (Main::Slice["db.config"].setup.plugins)
    end
  end

  specify "disabling sharing of config from the app" do
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
          after(:prepare) do
            @rom_config.plugin(:sql, relations: :auto_restrictions)
          end
        end
      RUBY

      write "slices/admin/config/providers/db.rb", <<~RUBY
        Admin::Slice.configure_provider :db do
          config.share_parent_config = false
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite://" + Pathname(@dir).realpath.join("database.db").to_s

      require "hanami/prepare"

      expect(Admin::Slice["db.config"].setup.plugins.length).to eq 0
    end
  end

  specify "slices using separate databases" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
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
