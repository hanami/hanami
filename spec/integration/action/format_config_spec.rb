# frozen_string_literal: true

require "json"
require "rack/test"

RSpec.describe "App action / Format config", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  around do |example|
    with_tmp_directory(Dir.mktmpdir, &example)
  end

  it "adds a body parser middleware for the accepted formats from the action config" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = StringIO.new

          config.actions.format :json
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      module TestApp
        class Routes < Hanami::Routes
          post "/users", to: "users.create"
        end
      end
    RUBY

    write "app/action.rb", <<~RUBY
      # auto_register: false

      module TestApp
        class Action < Hanami::Action
        end
      end
    RUBY

    write "app/actions/users/create.rb", <<~RUBY
      module TestApp
        module Actions
          module Users
            class Create < TestApp::Action
              def handle(req, res)
                res.body = req.params[:users].join("-")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    post(
      "/users",
      JSON.generate("users" => %w[jane john jade joe]),
      "CONTENT_TYPE" => "application/json"
    )

    expect(last_response).to be_successful
    expect(last_response.body).to eql("jane-john-jade-joe")
  end

  specify "adds a body parser middleware configured to parse any custom content type for the accepted formats" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = StringIO.new

          config.actions.formats.add :json, ["application/json+scim", "application/json"]
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      module TestApp
        class Routes < Hanami::Routes
          post "/users", to: "users.create"
        end
      end
    RUBY

    write "app/action.rb", <<~RUBY
      # auto_register: false

      module TestApp
        class Action < Hanami::Action
        end
      end
    RUBY

    write "app/actions/users/create.rb", <<~RUBY
      module TestApp
        module Actions
          module Users
            class Create < TestApp::Action
              def handle(req, res)
                res.body = req.params[:users].join("-")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    post(
      "/users",
      JSON.generate("users" => %w[jane john jade joe]),
      "CONTENT_TYPE" => "application/json+scim"
    )

    expect(last_response).to be_successful
    expect(last_response.body).to eql("jane-john-jade-joe")

    post(
      "/users",
      JSON.generate("users" => %w[jane john jade joe]),
      "CONTENT_TYPE" => "application/json"
    )

    expect(last_response).to be_successful
    expect(last_response.body).to eql("jane-john-jade-joe")
  end

  it "does not add a body parser middleware if one is already added" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = StringIO.new

          config.actions.format :json
          config.middleware.use :body_parser, [json: "application/json+custom"]
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      module TestApp
        class Routes < Hanami::Routes
          post "/users", to: "users.create"
        end
      end
    RUBY

    write "app/action.rb", <<~RUBY
      # auto_register: false

      module TestApp
        class Action < Hanami::Action
        end
      end
    RUBY

    write "app/actions/users/create.rb", <<~RUBY
      module TestApp
        module Actions
          module Users
            class Create < TestApp::Action
              config.formats.clear

              def handle(req, res)
                res.body = req.params[:users].join("-")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    post(
      "/users",
      JSON.generate("users" => %w[jane john jade joe]),
      "CONTENT_TYPE" => "application/json+custom"
    )

    expect(last_response).to be_successful
    expect(last_response.body).to eql("jane-john-jade-joe")
  end
end
