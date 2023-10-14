# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Hanami web app: Method Override", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  around do |example|
    with_tmp_directory(Dir.mktmpdir, &example)
  end

  context "enabled by default" do
    before do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      generate_app_code
    end

    it "overrides the original HTTP method" do
      post(
        "/users/:id",
        {"_method" => "PUT"},
        "CONTENT_TYPE" => "multipart/form-data"
      )

      expect(last_response).to be_successful
      expect(last_response.body).to eq("PUT")
    end
  end

  context "when disabled" do
    before do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.actions.method_override = false
          end
        end
      RUBY

      generate_app_code
    end

    it "overrides the original HTTP method" do
      post(
        "/users/:id",
        {"_method" => "PUT"},
        "CONTENT_TYPE" => "multipart/form-data"
      )

      expect(last_response).to_not be_successful
      expect(last_response.status).to be(404)
    end
  end

  private

  def generate_app_code
    write "config/routes.rb", <<~RUBY
      module TestApp
        class Routes < Hanami::Routes
          put "/users/:id", to: "users.update"
        end
      end
    RUBY

    write "app/actions/users/update.rb", <<~RUBY
      module TestApp
        module Actions
          module Users
            class Update < Hanami::Action
              def handle(req, res)
                res.body = req.env.fetch("REQUEST_METHOD")
              end
            end
          end
        end
      end
    RUBY

    require "hanami/boot"
  end
end
