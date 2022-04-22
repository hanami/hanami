# frozen_string_literal: true

RSpec.describe "Hanami view locals", :application_integration do
  specify "request params are available in view/template" do
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

      write "slices/main/actions/users/show.rb", <<~RUBY
        module Main
          module Actions
            module Users
              class Show < Action::Base
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
                expose :user
                expose :downcase_name
                expose :upcase_name do |user:|
                  user.fetch(:name).upcase
                end

                private

                def downcase_name(user:)
                  user.fetch(:name).downcase
                end
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
        h1 Hello, \#{user.fetch(:name)} (\#{upcase_name}, \#{downcase_name})
        h2 locals: \#{locals.keys}
      SLIM

      require "hanami/prepare"

      response = Main::Slice["actions.users.show"].(user: {name: "Jennifer"})
      expect(response.body.first).to eq "<html><body><h1>Hello, Jennifer (JENNIFER, jennifer)</h1><h2>locals: [:user]</h2></body></html>"
    end
  end

  specify "request params to be overwritten by response exposures" do
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

      write "slices/main/actions/users/show.rb", <<~RUBY
        module Main
          module Actions
            module Users
              class Show < Action::Base
                def handle(req, res)
                  klass = Struct.new(:id, :name, keyword_init: true)
                  user = klass.new(id: req.params.dig(:user, :id), name: "Amy")

                  res[:user] = user
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
                expose :user
                expose :downcase_name
                expose :upcase_name do |user:|
                  user.name.upcase
                end

                private

                def downcase_name(user:)
                  user.name.downcase
                end
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
        h1 Hello, \#{user.name} (\#{upcase_name}, \#{downcase_name})
        h2 locals: \#{locals.keys}
      SLIM

      require "hanami/prepare"

      response = Main::Slice["actions.users.show"].(user: {id: 23})
      expect(response.body.first).to eq "<html><body><h1>Hello, Amy (AMY, amy)</h1><h2>[:user]</h2></body></html>"
    end
  end
end
