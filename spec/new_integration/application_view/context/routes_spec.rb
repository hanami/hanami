# frozen_string_literal: true

require "hanami"
require "hanami/application/view/context"

RSpec.describe "Application view / Context / Routes", :application_integration do
  it "accesses application routes" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            define do
              slice :main, at: "/" do
                root to: "test_action"
              end
            end
          end
        end
      RUBY

      write "lib/test_app/view/context.rb", <<~RUBY
        require "hanami/application/view/context"

        module TestApp
          module View
            class Context < Hanami::Application::View::Context
            end
          end
        end
      RUBY

      write "slices/main/lib/view/context.rb", <<~RUBY
        module Main
          module View
            class Context < TestApp::View::Context
            end
          end
        end
      RUBY

      require "hanami/prepare"

      context = Main::View::Context.new
      expect(context.routes.path(:root)).to eq "/"
    end
  end

  it "can inject routes" do
    module TestApp
      class Application < Hanami::Application
      end
    end

    Hanami.prepare

    module TestApp
      module View
        class Context < Hanami::Application::View::Context
        end
      end
    end

    routes = double(:routes)

    context = TestApp::View::Context.new(routes: routes)

    expect(context.routes).to be(routes)
  end
end
