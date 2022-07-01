# frozen_string_literal: true

require "rack/test"

RSpec.describe "Slices / Slice routing", :application_integration do
  include Rack::Test::Methods

  let(:app) { Main::Slice.rack_app }

  specify "Slices have a nil router when no routes are defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/prepare"

      expect(Main::Slice.routes).to be nil
      expect(Main::Slice.router).to be nil
    end
  end

  specify "Slices have the application 'routes' component registered when application routes are defined but not their own" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger.stream = File.new("/dev/null", "w")
          end
        end
      RUBY

      write "config/routes.rb", <<~'RUBY'
        require "hanami/routes"

        module TestApp
          class Routes < Hanami::Routes
            define do
              slice :main, at: "/" do
                get "home", to: "home.show", as: :home
              end
            end
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/prepare"

      expect(Main::Slice["routes"]).to eql(TestApp::Application["routes"])
      expect(Main::Slice["routes"].path(:home)).to eq "/home"

      expect(Main::Slice.router).to be nil
      expect(TestApp::Application.router).not_to be nil
    end
  end

  specify "Slices use their own router and registered 'routes' component when their own routes are defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger.stream = File.new("/dev/null", "w")
          end
        end
      RUBY

      write "slices/main/config/routes.rb", <<~'RUBY'
        require "hanami/routes"

        module Main
          class Routes < Hanami::Routes
            define do
              get "home", to: "home.show", as: :home
            end
          end
        end
      RUBY

      write "slices/main/actions/home/show.rb", <<~'RUBY'
        require "hanami/action"

        module Main
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(*, res)
                  res.body = "Hello world"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"
      Main::Slice.boot

      expect(Main::Slice["routes"].path(:home)).to eq "/home"

      get "/home"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Hello world"
    end
  end

  describe "Mounting slice routes" do
    before :context do
      with_directory(@dir = make_tmp_directory) do
        write "config/application.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class Application < Hanami::Application
              config.logger.stream = File.new("/dev/null", "w")
            end
          end
        RUBY

        write "config/routes.rb", <<~'RUBY'
          module TestApp
            class Routes < Hanami::Routes
              define do
                root to: "home.show"

                slice :main, at: "/main"
              end
            end
          end
        RUBY

        write "app/actions/home/show.rb", <<~'RUBY'
          require "hanami/action"

          module TestApp
            module Actions
              module Home
                class Show < Hanami::Action
                  def handle(*, res)
                    res.body = "Hello from app"
                  end
                end
              end
            end
          end
        RUBY

        write "slices/main/config/routes.rb", <<~'RUBY'
          module Main
            class Routes < Hanami::Routes
              define do
                root to: "home.show"
              end
            end
          end
        RUBY

        write "slices/main/actions/home/show.rb", <<~'RUBY'
          require "hanami/action"

          module Main
            module Actions
              module Home
                class Show < Hanami::Action
                  def handle(*, res)
                    res.body = "Hello from slice"
                  end
                end
              end
            end
          end
        RUBY
      end
    end

    let(:app) { TestApp::Application.rack_app }

    describe "A slice with its own router can be mounted in its parent's routes" do
      context "prepared" do
        before do
          with_directory(@dir) { require "hanami/prepare" }
        end

        specify do
          get "/"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Hello from app"

          get "/main"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Hello from slice"
        end
      end

      context "booted" do
        before do
          with_directory(@dir) { require "hanami/boot" }
        end

        specify do
          get "/"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Hello from app"

          get "/main"

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq "Hello from slice"
        end
      end
    end
  end
end
