# frozen_string_literal: true

require "rack/test"

RSpec.describe "Hanami web app", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  around do |example|
    with_tmp_directory(Dir.mktmpdir, &example)
  end

  specify "Setting middlewares in the config" do
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.middleware.use :body_parser, :json
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

    write "app/actions/users/create.rb", <<~RUBY
      module TestApp
        module Actions
          module Users
            class Create < Hanami::Action
              accept :json

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
      JSON.dump("users" => %w[jane john jade joe]),
      "CONTENT_TYPE" => "application/json"
    )

    expect(last_response).to be_successful
    expect(last_response.body).to eql("jane-john-jade-joe")
  end
end
