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
