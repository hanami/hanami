# frozen_string_literal: true

require "rack/test"

RSpec.describe "Logging / Notifications", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  specify "Request logging continues even when notifications bus has already been used" do
    dir = Dir.mktmpdir

    with_tmp_directory(dir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.actions.format :json
            config.logger.options = {colorize: true}
            config.logger.stream = config.root.join("test.log")
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
                def handle(req, resp)
                  resp.body = req.params.to_h.keys
                end
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      # Simulate any component interacting with the notifications bus such that it creates its
      # internal bus with a duplicate copy of all currently registered events. This means that the
      # class-level Dry::Monitor::Notification events implicitly registered by the
      # Dry::Monitor::Rack::Middleware activated via the rack provider are ignored, unless our
      # provider explicitly re-registers them on _instance_ of the notifications bus.
      #
      # See Hanami::Providers::Rack for more detail.
      Hanami.app["notifications"].instrument(:sql)

      logs = -> { Pathname(dir).join("test.log").realpath.read }

      post "/users", JSON.generate(name: "jane", password: "secret"), {"CONTENT_TYPE" => "application/json"}
      expect(logs.()).to match %r{POST 200 \d+(µs|ms) 127.0.0.1 /}
    end
  end
end



