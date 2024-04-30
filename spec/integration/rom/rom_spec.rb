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

      write "app/db/posts.rb", <<~RUBY
        module TestApp
          module DB
            class Posts < ROM::Relation[:sql]
              schema :posts, infer: true
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"
      # ENV["DATABASE_URL"] = "postgres://postgres@localhost/hanami_rom_test"

      require "hanami/prepare"

      # Hack in an inline migration for now
      Hanami.app.prepare :db
      gateway = Hanami.app["db.connection"]
      puts "migrating"
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
      expect(Hanami.app["db.posts"]).to be Hanami.app["db.rom"].relations[:posts]
    end
  end
end
