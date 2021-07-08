# frozen_string_literal: true

require "rack/test"

RSpec.describe "Router with middleware", :application_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  specify "Middleware blah" do
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
        module TestApp
          class Middleware
            def self.called_as
              @called_as ||= Hash.new { |hsh, key| hsh[key] = [] }
            end

            def initialize(app, tag)
              @app = app
              @tag = tag
            end

            def call(env)
              self.class.called_as[@tag] << env["PATH_INFO"]
              @app.call(env)
            end
          end
        end

        Hanami.application.routes do
          slice :main, at: "/" do
            # With this here, it ends up applying to _all_ routes, including admin
            use TestApp::Middleware, :main

            root to: "home#show"
          end

          slice :admin, at: "/admin" do
            # With this here, all admin routes return 404
            use TestApp::Middleware, :admin

            root to: "home#show"
            get "test", to: "test#show"
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      write "slices/main/lib/main/actions/home/show.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(*, res)
                  res.body = "Hello from main"
                end
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/actions/home/show.rb", <<~RUBY
        require "hanami/action"

        module Admin
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(*, res)
                  res.body = "Hello from admin"
                end
              end
            end
          end
        end
      RUBY

      write "slices/admin/lib/admin/actions/test/show.rb", <<~RUBY
        require "hanami/action"

        module Admin
          module Actions
            module Test
              class Show < Hanami::Action
                def handle(*, res)
                  res.body = "Hello from admin test"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/boot"

      aggregate_failures do
        get "/"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "Hello from main"
        expect(TestApp::Middleware.called_as).to eq(main: ["/"])

        get "/admin"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "Hello from admin"
        expect(TestApp::Middleware.called_as).to eq(main: ["/"], admin: ["/admin"])

        get "/admin/test"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "Hello from admin test"
        expect(TestApp::Middleware.called_as).to eq(main: ["/"], admin: ["/admin", "/admin/test"])
      end
    end
  end
end
