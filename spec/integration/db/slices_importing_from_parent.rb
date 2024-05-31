# frozen_string_literal: true

RSpec.describe "DB / Slices / Importing from app", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "app DB components do not import into slices by default" do
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

      write "slices/admin/.keep", ""

      require "hanami/prepare"

      expect { Admin::Slice.start :db }.to raise_error Dry::System::ProviderNotFoundError
    end
  end

  specify "importing app DB components into slices via config.db.import_from_parent = true" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.db.import_from_parent = true
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

      write "slices/admin/.keep", ""

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      Hanami.app.prepare :db

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

      Admin::Slice.start :db

      expect(Admin::Slice["db.rom"]).to be(Hanami.app["db.rom"])
      expect(Admin::Slice["relations.posts"]).to be(Hanami.app["relations.posts"])

      expect(Admin::Slice["relations.posts"].to_a).to eq [{id: 1, title: "Together breakfast"}]
    end
  end

  specify "disabling import of the DB components within a specific slice" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.db.import_from_parent = true
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            config.db.import_from_parent = false
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

      require "hanami/prepare"

      expect { Admin::Slice.start :db }.to raise_error Dry::System::ProviderNotFoundError
    end
  end
end
