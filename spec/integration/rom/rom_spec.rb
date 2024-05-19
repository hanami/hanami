# frozen_string_literal: true

RSpec.describe "ROM", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "works?" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.inflections do |inflections|
              # TODO: Configure this by default
              inflections.acronym "DB"
            end
          end
        end
      RUBY

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < ROM::Relation[:sql]
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      # Hack in an inline migration for now
      Hanami.app.prepare :db
      gateway = Hanami.app["db.connection"]
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

  it "works with customising the provider source" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.inflections do |inflections|
              # TODO: Configure this by default
              inflections.acronym "DB"
            end
          end
        end
      RUBY

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < ROM::Relation[:sql]
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

      # Hack in an inline migration for now
      Hanami.app.prepare :db
      gateway = Hanami.app["db.connection"]
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
