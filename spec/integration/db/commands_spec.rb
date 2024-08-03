# frozen_string_literal: true

RSpec.describe "DB / Commands", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "registers custom commands" do
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

      write "app/db/commands/nested/create_post_with_default_title.rb", <<~RUBY
        module TestApp
          module DB
            module Commands
              module Nested
                class CreatePostWithDefaultTitle < ROM::SQL::Commands::Create
                  relation :posts
                  register_as :create_with_default_title
                  result :one

                  before :set_title

                  def set_title(tuple, *)
                    tuple[:title] ||= "Default title from command"
                    tuple
                  end
                end
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
            column :title, :text, null: false
          end
        end
      end
      migration.apply(gateway, :up)

      post = TestApp::App["relations.posts"].command(:create_with_default_title).call({})
      expect(post[:title]).to eq "Default title from command"
    end
  end
end
