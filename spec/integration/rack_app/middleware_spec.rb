# frozen_string_literal: true

require "rack/test"
require "stringio"

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
          config.logger.stream = StringIO.new

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
          slice :main, at: "/" do
            root to: "home.index"
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
          config.logger.stream = StringIO.new
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          slice :main, at: "/" do
            use TestApp::Middlewares::AppendOne
            use TestApp::Middlewares::Prepare, before: TestApp::Middlewares::AppendOne
            use TestApp::Middlewares::AppendTwo, after: TestApp::Middlewares::AppendOne

            root to: "home.index"
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

  specify "Setting a middleware that requires keyword arguments" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class TestMiddleware
          def initialize(app, key:, value:)
            @app = app
            @key = key
            @value = value
          end

          def call(env)
            env[@key] = @value
            @app.call(env)
          end
        end

        class App < Hanami::App
          config.logger.stream = StringIO.new

          # Test middleware with keywords inside config
          config.middleware.use(TestApp::TestMiddleware, key: "from_config", value: "config")
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          slice :main, at: "/" do
            # Also test middleware with keywords inside routes
            use TestApp::TestMiddleware, key: "from_routes", value: "routes"

            root to: "home.index"
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
              def handle(request, response)
                response.body = [request.env["from_config"], request.env["from_routes"]].join(", ")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    get "/"

    expect(last_response).to be_successful
    expect(last_response.body).to eq "config, routes"
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
          config.logger.stream = StringIO.new

          config.middleware.use(TestApp::TestMiddleware) { |env| env["tested"] = "yes" }
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      require "hanami/router"

      module TestApp
        class Routes < Hanami::Routes
          slice :main, at: "/" do
            root to: "home.index"
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

  context "Using module as a middleware" do
    it "sets the module as the middleware" do
      mod = Module.new
      app = Class.new(Hanami::App) { config.middleware.use(mod) }

      expect(app.config.middleware.stack["/"][0]).to include(mod)
    end
  end

  context "Setting an unsupported middleware" do
    it "raises meaningful error when an unsupported middleware spec was passed" do
      expect {
        Class.new(Hanami::App) do
          config.middleware.use("oops")
        end
      }.to raise_error(Hanami::UnsupportedMiddlewareSpecError)
    end

    it "raises meaningful error when corresponding file failed to load" do
      expect {
        Class.new(Hanami::App) do
          config.middleware.namespaces.delete(Hanami::Middleware)
          config.middleware.use(:body_parser)
        end
      }.to raise_error(Hanami::UnsupportedMiddlewareSpecError)
    end
  end

  context "with simple app" do
    before do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
            config.render_errors = true
          end
        end
      RUBY

      write "lib/test_app/middleware/authentication.rb", <<~RUBY
        module TestApp
          module Middleware
            class Authentication
              def self.inspect
                "<Middleware::Auth>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                env["AUTH_USER_ID"] = user_id = "23"
                status, headers, body = @app.call(env)
                headers["X-Auth-User-ID"] = user_id

                [status, headers, body]
              end
            end
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        require "test_app/middleware/authentication"

        module TestApp
          class Routes < Hanami::Routes
            root to: ->(*) { [200, {"Content-Length" => "4"}, ["Home"]] }

            slice :admin, at: "/admin" do
              use TestApp::Middleware::Authentication

              root to: "home.show"
            end
          end
        end
      RUBY

      write "slices/admin/actions/home/show.rb", <<~RUBY
        module Admin
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(req, res)
                  res.body = "Hello from admin (User ID " + req.env['AUTH_USER_ID'] + ")"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/boot"
    end

    it "excludes root scope" do
      get "/"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "Home"
      expect(last_response.headers).to_not have_key("X-Auth-User-ID")
    end

    it "excludes not found routes in root scope" do
      get "/foo"

      expect(last_response.status).to eq 404
      expect(last_response.headers).to_not have_key("X-Auth-User-ID")
    end

    context "within slice" do
      it "uses Rack middleware" do
        get "/admin"

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "Hello from admin (User ID 23)"
        expect(last_response.headers).to have_key("X-Auth-User-ID")
      end

      it "does not uses the Rack middleware for not found paths" do
        get "/admin/users"

        expect(last_response.status).to eq 404
        expect(last_response.headers).not_to have_key("X-Auth-User-ID")
      end
    end
  end

  context "with complex app" do
    let(:app_modules) { %i[TestApp Admin APIV1] }

    before do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
            config.render_errors = true
          end
        end
      RUBY

      write "lib/test_app/middleware/elapsed.rb", <<~RUBY
        module TestApp
          module Middleware
            class Elapsed
              def self.inspect
                "<Middleware::Elapsed>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                with_time_instrumentation do
                  @app.call(env)
                end
              end

              private

              def with_time_instrumentation
                starting = now
                status, headers, body = yield
                ending = now

                headers["X-Elapsed"] = (ending - starting).round(5).to_s
                [status, headers, body]
              end

              def now
                Process.clock_gettime(Process::CLOCK_MONOTONIC)
              end
            end
          end
        end
      RUBY

      write "lib/test_app/middleware/authentication.rb", <<~RUBY
        module TestApp
          module Middleware
            class Authentication
              def self.inspect
                "<Middleware::Auth>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                env["AUTH_USER_ID"] = user_id = "23"
                status, headers, body = @app.call(env)
                headers["X-Auth-User-ID"] = user_id

                [status, headers, body]
              end
            end
          end
        end
      RUBY

      write "lib/test_app/middleware/rate_limiter.rb", <<~RUBY
        module TestApp
          module Middleware
            class RateLimiter
              def self.inspect
                "<Middleware::API::Limiter>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                status, headers, body = @app.call(env)
                headers["X-API-Rate-Limit-Quota"] = "4000"

                [status, headers, body]
              end
            end
          end
        end
      RUBY

      write "lib/test_app/middleware/api_version.rb", <<~RUBY
        module TestApp
          module Middleware
            class ApiVersion
              def self.inspect
                "<Middleware::API::Version>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                status, headers, body = @app.call(env)
                headers["X-API-Version"] = "1"

                [status, headers, body]
              end
            end
          end
        end
      RUBY

      write "lib/test_app/middleware/api_deprecation.rb", <<~RUBY
        module TestApp
          module Middleware
            class ApiDeprecation
              def self.inspect
                "<Middleware::API::Deprecation>"
              end

              def initialize(app)
                @app = app
              end

              def call(env)
                status, headers, body = @app.call(env)
                headers["X-API-Deprecated"] = "API v1 is deprecated"

                [status, headers, body]
              end
            end
          end
        end
      RUBY

      write "lib/test_app/middleware/scope_identifier.rb", <<~RUBY
        module TestApp
          module Middleware
            class ScopeIdentifier
              def self.inspect
                "<Middleware::API::ScopeIdentifier>"
              end

              def initialize(app, scope)
                @app = app
                @scope = scope
              end

              def call(env)
                status, header, body = @app.call(env)
                header["X-Identifier-" + @scope] = "true"
                [status, header, body]
              end

              def inspect
                "Scope identifier: " + @scope.inspect
              end
            end
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        require "test_app/middleware/elapsed"
        require "test_app/middleware/authentication"
        require "test_app/middleware/rate_limiter"
        require "test_app/middleware/api_version"
        require "test_app/middleware/api_deprecation"
        require "test_app/middleware/scope_identifier"

        module TestApp
          class Routes < Hanami::Routes
            use TestApp::Middleware::Elapsed
            use TestApp::Middleware::ScopeIdentifier, "Root"
            root to: ->(*) { [200, {"Content-Length" => "4"}, ["Home (complex app)"]] }

            mount ->(*) { [200, {"Content-Length" => "7"}, ["Mounted"]] }, at: "/mounted"

            slice :admin, at: "/admin" do
              use TestApp::Middleware::Authentication
              use TestApp::Middleware::ScopeIdentifier, "Admin"

              root to: "home.show"
            end

            # Without leading slash
            # See: https://github.com/hanami/api/issues/8
            scope "api" do
              use TestApp::Middleware::RateLimiter
              use TestApp::Middleware::ScopeIdentifier, "API"

              root to: ->(*) { [200, {"Content-Length" => "3"}, ["API"]] }

              slice :api_v1, at: "/v1" do
                use TestApp::Middleware::ApiVersion
                use TestApp::Middleware::ApiDeprecation
                use TestApp::Middleware::ScopeIdentifier, "API-V1"

                root to: "home.show"
              end
            end
          end
        end
      RUBY

      write "slices/admin/actions/home/show.rb", <<~RUBY
        module Admin
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(req, res)
                  res.body = "Hello from admin (User ID " + req.env['AUTH_USER_ID'] + ")"
                end
              end
            end
          end
        end
      RUBY

      write "slices/api_v1/actions/home/show.rb", <<~RUBY
        module APIV1
          module Actions
            module Home
              class Show < Hanami::Action
                def handle(req, res)
                  res.body = "API v1"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/boot"
    end

    it "uses Rack middleware" do
      get "/"

      expect(last_response.status).to be(200)
      expect(last_response.body).to eq("Home (complex app)")
      expect(last_response.headers["X-Identifier-Root"]).to eq("true")
      expect(last_response.headers).to have_key("X-Elapsed")
      expect(last_response.headers).to_not have_key("X-Auth-User-ID")
      expect(last_response.headers).to_not have_key("X-API-Rate-Limit-Quota")
      expect(last_response.headers).to_not have_key("X-API-Version")
    end

    it "does not use Rack middleware for other paths" do
      get "/__not_found__"

      expect(last_response.status).to eq 404
      expect(last_response.headers).not_to have_key("X-Identifier-Root")
      expect(last_response.headers).not_to have_key("X-Elapsed")
      expect(last_response.headers).not_to have_key("X-Auth-User-ID")
      expect(last_response.headers).not_to have_key("X-API-Rate-Limit-Quota")
      expect(last_response.headers).not_to have_key("X-API-Version")
    end

    context "scoped" do
      it "uses Rack middleware" do
        get "/admin"

        expect(last_response.status).to be(200)
        expect(last_response.headers["X-Identifier-Admin"]).to eq("true")
        expect(last_response.headers).to have_key("X-Elapsed")
        expect(last_response.headers).to have_key("X-Auth-User-ID")
        expect(last_response.headers).to_not have_key("X-API-Rate-Limit-Quota")
        expect(last_response.headers).to_not have_key("X-API-Version")
      end

      it "uses Rack middleware for other paths" do
        get "/admin/__not_found__"

        expect(last_response.status).to eq 404
        expect(last_response.headers).not_to have_key("X-Identifier-Admin")
        expect(last_response.headers).not_to have_key("X-Elapsed")
        expect(last_response.headers).not_to have_key("X-Elapsed")
        expect(last_response.headers).not_to have_key("X-Auth-User-ID")
        expect(last_response.headers).not_to have_key("X-API-Rate-Limit-Quota")
        expect(last_response.headers).not_to have_key("X-API-Version")
      end

      # See: https://github.com/hanami/api/issues/8
      it "uses Rack middleware for scope w/o leading slash" do
        get "/api"

        expect(last_response.status).to be(200)
        expect(last_response.headers["X-Identifier-Api"]).to eq("true")
        expect(last_response.headers).to have_key("X-Elapsed")
        expect(last_response.headers).to_not have_key("X-Auth-User-ID")
        expect(last_response.headers).to have_key("X-API-Rate-Limit-Quota")
        expect(last_response.headers).to_not have_key("X-API-Version")
      end

      # See: https://github.com/hanami/api/issues/8
      it "uses Rack middleware for nested scope w/o leading slash" do
        get "/api/v1"

        expect(last_response.status).to be(200)
        expect(last_response.headers["X-Identifier-API-V1"]).to eq("true")
        expect(last_response.headers).to have_key("X-Elapsed")
        expect(last_response.headers).to_not have_key("X-Auth-User-ID")
        expect(last_response.headers).to have_key("X-API-Rate-Limit-Quota")
        expect(last_response.headers).to have_key("X-API-Deprecated")
        expect(last_response.headers["X-API-Version"]).to eq("1")
      end
    end
  end
end
