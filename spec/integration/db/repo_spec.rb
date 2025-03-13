# frozen_string_literal: true

RSpec.describe "DB / Repo", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "repos have a root inferred from their name, or can set their own" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/repo.rb", <<~RUBY
        module TestApp
          class Repo < Hanami::DB::Repo
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

      write "app/repos/post_repo.rb", <<~RUBY
        module TestApp
          module Repos
            class PostRepo < Repo
              def get(id)
                posts.by_pk(id).one!
              end
            end
          end
        end
      RUBY

      write "app/repos/no_implicit_root_relation_repo.rb", <<~RUBY
        module TestApp
          module Repos
            class NoImplicitRootRelationRepo < Repo
            end
          end
        end
      RUBY

      write "app/repos/explicit_root_relation_repo.rb", <<~RUBY
        module TestApp
          module Repos
            class ExplicitRootRelationRepo < Repo[:posts]
            end
          end
        end
      RUBY

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

      # Repos use a matching root relation automatically
      repo = Hanami.app["repos.post_repo"]
      expect(repo.get(1).title).to eq "Together breakfast"
      expect(repo.root).to eql Hanami.app["relations.posts"]

      # Non-matching repos still work, just with no root relation
      repo = Hanami.app["repos.no_implicit_root_relation_repo"]
      expect(repo.root).to be nil

      # Repos can provide an explicit root relation
      repo = Hanami.app["repos.explicit_root_relation_repo"]
      expect(repo.root).to eql Hanami.app["relations.posts"]
    end
  end

  specify "repos use relations and structs only from their own slice" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/repo.rb", <<~RUBY
        module TestApp
          class Repo < Hanami::DB::Repo
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      write "slices/admin/db/struct.rb", <<~RUBY
        module Admin
          module DB
            class Struct < Hanami::DB::Struct
            end
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

      write "slices/admin/repo.rb", <<~RUBY
        module Admin
          class Repo < TestApp::Repo
          end
        end
      RUBY

      write "slices/admin/repos/post_repo.rb", <<~RUBY
        module Admin
          module Repos
            class PostRepo < Repo
            end
          end
        end
      RUBY

      write "slices/admin/structs/post.rb", <<~RUBY
        module Admin
          module Structs
            class Post < DB::Struct
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

      write "slices/main/repo.rb", <<~RUBY
        module Main
          class Repo < TestApp::Repo
          end
        end
      RUBY

      write "slices/main/repos/post_repo.rb", <<~RUBY
        module Main
          module Repos
            class PostRepo < Repo
            end
          end
        end
      RUBY

      require "hanami/prepare"

      Admin::Slice.prepare :db

      # Manually run a migration
      gateway = Admin::Slice["db.gateway"]
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

      expect(Admin::Slice["repos.post_repo"].root).to eql Admin::Slice["relations.posts"]
      expect(Admin::Slice["repos.post_repo"].posts).to eql Admin::Slice["relations.posts"]
      expect(Admin::Slice["repos.post_repo"].posts.by_pk(1).one!.class).to be < Admin::Structs::Post

      expect(Main::Slice["repos.post_repo"].posts).to eql Main::Slice["relations.posts"]
      # Slice struct namespace used even when no concrete struct classes are defined
      expect(Main::Slice["repos.post_repo"].posts.by_pk(1).one!.class).to be < Main::Structs::Post
    end
  end
end
