# frozen_string_literal: true

require "rack/test"
require "stringio"

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
        end
      end
    RUBY

    write "config/routes.rb", <<~RUBY
      module TestApp
        class Routes < Hanami::Routes
          put "/users/:id", to: "users.update"
        end
      end
    RUBY

    write "app/actions/users/update.rb", <<~'RUBY'
      module TestApp
        module Actions
          module Users
            class Update < Hanami::Action
              def handle(request, response)
                response.redirect_to "/users/#{request.params[:id]}"
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"

    post(
      "/users/123",
      {"_method" => "put", "name" => "Jane"},
    )

    expect(last_response).to be_redirect
    expect(last_response.location).to eq "/users/123"
  end
end
