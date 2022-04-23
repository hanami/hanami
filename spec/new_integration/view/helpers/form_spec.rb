# frozen_string_literal: true

RSpec.describe "View helpers / Form", :application_integration do
  specify "exposes helper" do
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
          class Routes < Hanami::Application::Routes
            define do
              slice :main, at: "/" do
                post "/users", to: "users.create", as: :users
              end
            end
          end
        end
      RUBY

      write "lib/test_app/action/base.rb", <<~RUBY
        require "hanami/application/action"

        module TestApp
          module Action
            class Base < Hanami::Application::Action
            end
          end
        end
      RUBY

      write "lib/test_app/view/base.rb", <<~RUBY
        require "hanami/application/view"

        module TestApp
          module View
            class Base < Hanami::Application::View
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

      write "slices/main/lib/action/base.rb", <<~RUBY
        require "test_app/action/base"

        module Main
          module Action
            class Base < TestApp::Action::Base
            end
          end
        end
      RUBY

      write "slices/main/lib/view/base.rb", <<~RUBY
        require "test_app/view/base"

        module Main
          module View
            class Base < TestApp::View::Base
            end
          end
        end
      RUBY

      write "slices/main/lib/view/context.rb", <<~RUBY
        require "test_app/view/context"

        module Main
          module View
            class Context < TestApp::View::Context
            end
          end
        end
      RUBY

      write "slices/main/actions/users/new.rb", <<~RUBY
        module Main
          module Actions
            module Users
              class New < Action::Base
              end
            end
          end
        end
      RUBY

      write "slices/main/views/users/new.rb", <<~RUBY
        module Main
          module Views
            module Users
              class New < View::Base
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/users/new.html.slim", <<~SLIM
        = context.form_for(context.routes.path(:users), data: locals) {}
      SLIM

      require "hanami/prepare"

      response = Main::Slice["actions.users.new"].({})
      actual = response.body.first
      expected = [
        "<html>",
        "<body>",
        %(<form action="/users" method="POST" accept-charset="utf-8"></form>),
        "</body>",
        "</html>"
      ]

      expected.each do |line|
        expect(actual).to include(line)
      end
    end
  end
end
