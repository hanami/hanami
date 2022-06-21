# frozen_string_literal: true

RSpec.describe "Application action / Routes", :application_integration do
  specify "Access application routes from an action" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application; end
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

      write "lib/test_app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action; end
        end
      RUBY

      write "slices/main/actions/test_action.rb", <<~RUBY
        module Main
          module Actions
            class TestAction < TestApp::Action
              def handle(req, res)
                res.body = routes.path(:root)
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      response = Main::Slice["actions.test_action"].call({})
      expect(response.body).to eq ["/"]
    end
  end
end
