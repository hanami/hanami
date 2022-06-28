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
              root to: "home.index"

              slice :admin, at: "/admin" do
                root to: "dashboard.index"
              end
            end
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action; end
        end
      RUBY

      write "app/actions/home/index.rb", <<~RUBY
        module TestApp
          module Actions
            module Home
              class Index < TestApp::Action
                def handle(req, res)
                  res.body = routes.path(:root)
                end
              end
            end
          end
        end
      RUBY

      write "slices/admin/actions/dashboard/index.rb", <<~RUBY
        module Admin
          module Actions
            module Dashboard
              class Index < TestApp::Action
                def handle(req, res)
                  res.body = routes.path(:admin_root)
                end
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      response = TestApp::Application["actions.home.index"].call({})
      expect(response.body).to eq ["/"]

      response = Admin::Slice["actions.dashboard.index"].call({})
      expect(response.body).to eq ["/admin"]
    end
  end
end
