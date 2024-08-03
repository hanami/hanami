# frozen_string_literal: true

RSpec.describe "DB / Mappers", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  it "registers custom mappers" do
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

      write "app/db/mappers/nested/default_title_mapper.rb", <<~RUBY
        require "rom/transformer"

        module TestApp
          module DB
            module Mappers
              module Nested
                class DefaultTitleMapper < ROM::Transformer
                  relation :posts
                  register_as :default_title_mapper

                  map do
                    set_default_title
                  end

                  def set_default_title(row)
                    row[:title] ||= "Default title from mapper"
                    row
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
            column :title, :text
          end
        end
      end
      migration.apply(gateway, :up)
      gateway.connection.execute("INSERT INTO posts (title) VALUES (NULL)")

      post = TestApp::App["relations.posts"].map_with(:default_title_mapper).to_a[0]
      expect(post[:title]).to eq "Default title from mapper"
    end
  end
end
