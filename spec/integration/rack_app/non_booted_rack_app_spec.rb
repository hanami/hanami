# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Running a Rack app for a non-booted app", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  it "lazy loads only the components required for any accessed routes" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        require "hanami/routes"

        module TestApp
          class Routes < Hanami::Routes
            slice :main, at: "/" do
              root to: "home.show"
              get "/articles", to: "articles.index"
            end
          end
        end
      RUBY

      write "slices/main/lib/action.rb", <<~RUBY
        # auto_register: false

        require "hanami/action"

        module Main
          class Action < Hanami::Action
          end
        end
      RUBY

      write "slices/main/lib/article_repo.rb", <<~RUBY
        module Main
          class ArticleRepo < Hanami::Action
          end
        end
      RUBY

      write "slices/main/lib/greeter.rb", <<~RUBY
        module Main
          class Greeter
            def greeting
              "Hello world"
            end
          end
        end
      RUBY

      write "slices/main/actions/home/show.rb", <<~RUBY
        module Main
          module Actions
            module Home
              class Show < Main::Action
                include Deps["greeter"]

                def handle(req, res)
                  res.body = greeter.greeting
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/actions/articles/index.rb", <<~RUBY
        module Main
          module Actions
            module Articles
              class Index < Main::Action
                include Deps["article_repo"]
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      get "/"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Hello world"

      expect(Hanami.app).not_to be_booted
      expect(Main::Slice.keys).to include(*%w[actions.home.show greeter])
      expect(Main::Slice.keys).not_to include(*%w[actions.articles.index article_repo])
    end
  end
end
