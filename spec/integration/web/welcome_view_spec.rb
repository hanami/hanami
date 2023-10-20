# frozen_string_literal: true

require "json"
require "rack/test"

RSpec.describe "Web / Welcome view", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  context "no routes defined" do
    it "renders the welcome page" do
      get "/"

      body = last_response.body.strip
      expect(body).to include "<h1>Welcome to Hanami</h1>"
      expect(body).to include "Hanami version: #{Hanami::VERSION}"
      expect(body).to include "Ruby version: #{RUBY_DESCRIPTION}"

      expect(last_response.status).to eq 200
    end
  end

  context "routes defined" do
    def before_prepare
      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: -> * { [200, {}, "Hello from a route"] }
          end
        end
      RUBY
    end

    it "does not render the welcome page" do
      get "/"

      expect(last_response.body).to eq "Hello from a route"
      expect(last_response.status).to eq 200
    end
  end

  context "non-development env" do
    def before_prepare
      @hanami_env = ENV["HANAMI_ENV"]
      ENV["HANAMI_ENV"] = "production"
    end

    after do
      ENV["HANAMI_ENV"] = @hanami_env
    end

    it "does not render the welcome page" do
      get "/"

      expect(last_response.body).to eq "Not Found"
      expect(last_response.status).to eq 404
    end
  end
end
