# frozen_string_literal: true

require "rack/test"

RSpec.describe "Hanami web app", :application_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  specify "Routing to actions based on their container identifiers" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger = {stream: File.new("/dev/null", "w")}
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        Hanami.application.routes do
          mount :admin, at: "/admin" do
            get "dashboard", to: "dashboard.show"
          end

          mount :main, at: "/" do
            root to: "home"
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      write "slices/main/lib/main/actions/home.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Home < Hanami::Action
              def handle(_req, res)
                res.body = "Hello world"
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/actions/dashboard/show.rb", <<~RUBY
        require "hanami/action"

        module Admin
          module Actions
            module Dashboard
              class Show < Hanami::Action
                def handle(_req, res)
                  res.body = "Admin dashboard here"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/boot"

      get "/"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Hello world"

      get "/admin/dashboard"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Admin dashboard here"
    end
  end
end
