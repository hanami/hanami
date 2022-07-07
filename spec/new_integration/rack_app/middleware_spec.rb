# frozen_string_literal: true

require "rack/test"

RSpec.describe "Hanami web app", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  around do |example|
    with_tmp_directory(Dir.mktmpdir, &example)
  end

  before do
    module TestApp
      module Middlewares
        class Core
          def initialize(app)
            @app = app
          end
        end

        class Prepare < Core
          def call(env)
            env["tested"] = []
            @app.call(env)
          end
        end

        class AppendOne < Core
          def call(env)
            env["tested"] << "one"
            @app.call(env)
          end
        end

        class AppendTwo < Core
          def call(env)
            env["tested"] << "two"
            @app.call(env)
          end
        end
      end
    end
  end

  specify "Setting middlewares in the config" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = File.new("/dev/null", "w")

          config.middleware.use Middlewares::AppendOne
          config.middleware.use Middlewares::Prepare, before: Middlewares::AppendOne
          config.middleware.use Middlewares::AppendTwo, after: Middlewares::AppendOne
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          define do
            slice :main, at: "/" do
              root to: "home.index"
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
              def handle(req, res)
                res.body = req.env["tested"].join(".")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    get "/"

    expect(last_response).to be_successful
    expect(last_response.body).to eql("one.two")
  end

  specify "Setting middlewares in the router" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = File.new("/dev/null", "w")
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          define do
            slice :main, at: "/" do
              use TestApp::Middlewares::AppendOne
              use TestApp::Middlewares::Prepare, before: TestApp::Middlewares::AppendOne
              use TestApp::Middlewares::AppendTwo, after: TestApp::Middlewares::AppendOne

              root to: "home.index"
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
              def handle(req, res)
                res.body = req.env["tested"].join(".")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    get "/"

    expect(last_response).to be_successful
    expect(last_response.body).to eql("one.two")
  end

  specify "Setting a middleware that requires a block" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class TestMiddleware
          def initialize(app, &block)
            @app = app
            @block = block
          end

          def call(env)
            @block.call(env)
            @app.call(env)
          end
        end

        class App < Hanami::App
          config.logger.stream = File.new("/dev/null", "w")

          config.middleware.use(TestApp::TestMiddleware) { |env| env["tested"] = "yes" }
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          define do
            slice :main, at: "/" do
              root to: "home.index"
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
              def handle(req, res)
                res.body = req.env["tested"]
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    get "/"

    expect(last_response).to be_successful
    expect(last_response.body).to eql("yes")
  end
end
