# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Web / Content security policy nonce in a slice", :app_integration do
  include Rack::Test::Methods

  let(:app) { Main::Slice.rack_app }

  specify "A slice serving its own routes generates nonces from its own config" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.actions.content_security_policy[:script_src] = "'self' 'nonce'"
            config.actions.content_security_policy_nonce_generator = -> { "app-nonce" }

            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "slices/main/config/slice.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
            config.actions.content_security_policy_nonce_generator = -> { "slice-nonce" }
          end
        end
      RUBY

      write "slices/main/config/routes.rb", <<~RUBY
        module Main
          class Routes < Hanami::Routes
            get "home", to: "home.show"
          end
        end
      RUBY

      write "slices/main/actions/home/show.rb", <<~RUBY
        module Main
          module Actions
            module Home
              class Show < TestApp::Action
                def handle(*, res)
                  res.body = "Hello world"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      get "/home"

      expect(last_request.env["hanami.content_security_policy_nonce"]).to eq "slice-nonce"
      expect(last_response.get_header("Content-Security-Policy")).to include "'nonce-slice-nonce'"
    end
  end
end
