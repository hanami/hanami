# frozen_string_literal: true

RSpec.describe "Hanami view integration", :application_integration do
  specify "Views take their configuration from their slice in which they are defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/view.rb", <<~RUBY
        require "hanami/application/view"

        module Main
          class View < Hanami::Application::View
          end
        end
      RUBY

      write "slices/main/lib/views/test_view.rb", <<~RUBY
        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

      rendered = Main::Slice["views.test_view"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end

  specify "Views can also take configuration from the application when defined in the top-level application module" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/view.rb", <<~RUBY
        # auto_register: false
        require "hanami/application/view"

        module Main
          class View < Hanami::Application::View
          end
        end
      RUBY

      write "slices/main/views/test_view.rb", <<~RUBY
        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

      rendered = Main::Slice["views.test_view"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end

  specify "Canonical views setup" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
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
        require "hanami/view/context"

        module TestApp
          module View
            class Context < Hanami::View::Context
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

      write "slices/main/views/users/show.rb", <<~RUBY
        module Main
          module Views
            module Users
              class Show < View::Base
                expose :name
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

      write "slices/main/templates/users/show.html.slim", <<~SLIM
        h1 Hello, \#{name}
      SLIM

      require "hanami/prepare"

      rendered = Main::Slice["views.users.show"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end

  specify "Canonical action rendering" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
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
        require "hanami/view/context"

        module TestApp
          module View
            class Context < Hanami::View::Context
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

      write "slices/main/actions/users/show.rb", <<~RUBY
        module Main
          module Actions
            module Users
              class Show < Action::Base
                def handle(req, res)
                  res[:name] = req.params[:name]
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/views/users/show.rb", <<~RUBY
        module Main
          module Views
            module Users
              class Show < View::Base
                expose :name
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

      write "slices/main/templates/users/show.html.slim", <<~SLIM
        h1 Hello, \#{name}
      SLIM

      require "hanami/prepare"

      response = Main::Slice["actions.users.show"].(name: "Jennifer")
      expect(response.body.first).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end
end
