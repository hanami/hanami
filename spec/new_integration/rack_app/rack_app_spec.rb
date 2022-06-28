# frozen_string_literal: true

require "rack/test"

RSpec.describe "Hanami web app", :application_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.rack_app }

  specify "has rack monitor preconfigured with default request logging" do
    dir = Dir.mktmpdir

    with_tmp_directory(dir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger.stream = config.root.join("test.log")
          end
        end
      RUBY

      require "hanami/boot"

      expect(Hanami.application[:rack_monitor]).to be_instance_of(Dry::Monitor::Rack::Middleware)

      get "/"

      logs = -> { Pathname(dir).join("test.log").realpath.read }

      expect(logs.()).to match %r{GET 404 \d+ms 127.0.0.1 /}
    end
  end

  specify "Routing to actions based on their container identifiers" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger.stream = File.new("/dev/null", "w")
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            define do
              get "/health", to: "health.show"

              get "/inline" do
                "Inline"
              end

              slice :main, at: "/" do
                root to: "home.index"
              end

              slice :admin, at: "/admin" do
                get "/dashboard", to: "dashboard.show"
              end
            end
          end
        end
      RUBY

      write "app/actions/health/show.rb", <<~RUBY
        require "hanami/action"

        module TestApp
          module Actions
            module Health
              class Show < Hanami::Action
                def handle(*, res)
                  res.body = "Health, OK"
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/actions/home/index.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            module Home
              class Index < Hanami::Action
                def handle(*, res)
                  res.body = "Hello world"
                end
              end
            end
          end
        end
      RUBY

      write "slices/admin/actions/dashboard/show.rb", <<~RUBY
        require "hanami/action"

        module Admin
          module Actions
            module Dashboard
              class Show < Hanami::Action
                def handle(*, res)
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

      get "/inline"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Inline"

      get "/health"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Health, OK"

      get "/admin/dashboard"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Admin dashboard here"
    end
  end

  specify "It doesn't boot the app, if referenced action isn't registered" do
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
              get "/missing", to: "missing.action"
            end
          end
        end
      RUBY

      expect { require "hanami/boot" }.to raise_error do |exception|
        expect(exception).to be_kind_of(Hanami::Application::Routing::UnknownActionError)
        expect(exception.message).to include("missing.action")
      end
    end
  end
end
