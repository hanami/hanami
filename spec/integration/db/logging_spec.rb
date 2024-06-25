# frozen_string_literal: true

RSpec.describe "DB / Logging", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "logs SQL queries" do
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

      require "hanami/setup"

      logger_stream = StringIO.new
      Hanami.app.config.logger.stream = logger_stream

      require "hanami/prepare"

      Hanami.app.prepare :db

      # Manually run a migration and add a test record
      gateway = Hanami.app["db.gateway"]
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

      relation = Hanami.app["relations.posts"]
      expect(relation.select(:title).to_a).to eq [{:title=>"Together breakfast"}]

      logger_stream.rewind
      log_lines = logger_stream.read.split("\n")

      expect(log_lines.length).to eq 1
      expect(log_lines.first).to match /Loaded :sqlite in \d+ms SELECT `posts`.`title` FROM `posts` ORDER BY `posts`.`id`/
    end
  end
end
