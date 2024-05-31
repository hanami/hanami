# frozen_string_literal: true

RSpec.describe "DB", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "sets up ROM and reigsters relations" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
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

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      Hanami.app.prepare :db

      expect(Hanami.app["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Hanami.app["db.gateway"]).to be_an_instance_of ROM::SQL::Gateway

      # Manually run a migration and add a test record
      gateway = Hanami.app["db.gateway"]
      migration = gateway.migration do
        change do
          # drop_table? :posts
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      Hanami.app.boot

      expect(Hanami.app["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Hanami.app["relations.posts"]).to be Hanami.app["db.rom"].relations[:posts]
    end
  end

  it "provides access in a non-booted app" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
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

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      Hanami.app.prepare :db

      expect(Hanami.app["db.config"]).to be_an_instance_of ROM::Configuration
      expect(Hanami.app["db.gateway"]).to be_an_instance_of ROM::SQL::Gateway

      # Manually run a migration and add a test record
      gateway = Hanami.app["db.gateway"]
      migration = gateway.migration do
        change do
          # drop_table? :posts
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      expect(Hanami.app["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Hanami.app["relations.posts"]).to be Hanami.app["db.rom"].relations[:posts]
    end
  end

  it "raises an error when now database URL is provided" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.inflections do |inflections|
            end
          end
        end
      RUBY

      write "app/relations/.keep", ""

      require "hanami/prepare"

      expect { Hanami.app.prepare :db }.to raise_error(Hanami::ComponentLoadError, /database_url/)
    end
  end

  it "allows the user to configure the provider" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
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

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          configure do |config|
            # In this test, we're not setting an ENV["DATABASE_URL"], and instead configuring
            # it via the provider source config, to prove that this works

            config.database_url = "sqlite::memory"
          end
        end
      RUBY

      require "hanami/prepare"

      Hanami.app.prepare :db
      gateway = Hanami.app["db.gateway"]
      migration = gateway.migration do
        change do
          # drop_table? :posts
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Together breakfast')")

      Hanami.app.boot

      expect(Hanami.app["db.rom"].relations[:posts].to_a).to eq [{id: 1, title: "Together breakfast"}]
      expect(Hanami.app["relations.posts"]).to be Hanami.app["db.rom"].relations[:posts]
    end
  end
end
