# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Context / Routes", :app_integration do
  it "accesses app routes" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: "home.index"
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        require "hanami/action"

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/actions/home/index.rb", <<~RUBY
        module TestApp
          module Actions
            module Home
              class Index < Hanami::Action
              end
            end
          end
        end
      RUBY

      write "app/views/context.rb", <<~RUBY
        require "hanami/view/context"

        module TestApp
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      require "hanami/prepare"

      context = TestApp::Views::Context.new
      expect(context.routes.path(:root)).to eq "/"
    end
  end

  it "accesses app routes from a slice context, including the prefix the slice is mounted at" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: "home.index"

            slice :main, at: "/main"
          end
        end
      RUBY

      write "app/actions/home/index.rb", <<~RUBY
        require "hanami/action"

        module TestApp
          module Actions
            module Home
              class Index < Hanami::Action
              end
            end
          end
        end
      RUBY

      write "slices/main/config/routes.rb", <<~RUBY
        module Main
          class Routes < Hanami::Routes
            get "/posts", to: "posts.index", as: :posts
          end
        end
      RUBY

      write "slices/main/actions/posts/index.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            module Posts
              class Index < Hanami::Action
              end
            end
          end
        end
      RUBY

      write "slices/main/views/context.rb", <<~RUBY
        require "hanami/view/context"

        module Main
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      require "hanami/prepare"

      context = Main::Views::Context.new

      # The slice's own "routes" component knows this route as :posts at "/posts", missing the
      # prefix it is mounted at, and does not know :root at all.
      expect(context.routes.path(:main_posts)).to eq "/main/posts"
      expect(context.routes.path(:root)).to eq "/"
    end
  end

  it "can inject routes" do
    module TestApp
      class App < Hanami::App
      end
    end

    Hanami.prepare

    module TestApp
      module Views
        class Context < Hanami::View::Context
        end
      end
    end

    routes = double(:routes)

    context = TestApp::Views::Context.new(routes: routes)

    expect(context.routes).to be(routes)
  end
end
