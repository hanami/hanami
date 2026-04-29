# frozen_string_literal: true

RSpec.describe "App action / Dependency injection", :app_integration do
  specify "Custom view injection works as intended" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/logger", <<~RUBY
        require "logger"

        module TestApp
          class Logger < ::Logger
            def initialize
              super(STDOUT)
            end
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action
            include Deps["logger"]
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "app/actions/users/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Users
              class Show < TestApp::Action
                include Deps[view: "views.users.show"]

                def handle(req, res)
                  res.render view
                end
              end
            end
          end
        end
      RUBY

      write "app/views/users/show.rb", <<~RUBY
        module TestApp
          module Views
            module Users
              class Show < TestApp::View
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      action = TestApp::App["actions.users.show"]

      expect(action.view).to be_a TestApp::Views::Users::Show
    end
  end
end
