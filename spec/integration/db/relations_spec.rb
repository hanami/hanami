# frozen_string_literal: true

RSpec.describe "DB / Relations", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "registers nested relations" do
    with_tmp_directory(@dir = Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "app/relations/nested/posts.rb", <<~RUBY
        module TestApp
          module Relations
            module Nested
              class Posts < Hanami::DB::Relation
                schema :posts, infer: true
              end
            end
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      Hanami.app.prepare :db

      # Manually run a migration and add a test record
      gateway = TestApp::App["db.gateway"]
      migration = gateway.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, :text
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES ('Hi from nested relation')")

      post = TestApp::App["relations.posts"].to_a[0]
      expect(post[:title]).to eq "Hi from nested relation"
    end
  end
end
