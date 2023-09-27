# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Serve Static Assets", :app_integration do
  include Rack::Test::Methods
  let(:app) { Hanami.app }
  let(:root) { make_tmp_directory }
  let!(:env) { ENV.to_h }

  before do
    with_directory(root) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: ->(env) { [200, {}, ["Hello from root"]] }
          end
        end
      RUBY

      write "public/assets/app.js", <<~JS
        console.log("Hello from app.js");
      JS
    end
  end

  after do
    ENV.replace(env)
  end

  context "with default configuration" do
    before do
      with_directory(root) do
        require "hanami/prepare"
      end
    end

    it "serves static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to match(/Hello/)
    end

    it "returns 404 for missing asset" do
      get "/assets/missing.js"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to match(/Not Found/i)
    end

    it "doesn't escape from root directory" do
      get "/assets/../../config/app.rb"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to match(/Not Found/i)
    end
  end

  context "when configuration is set to false" do
    before do
      with_directory(root) do
        write "config/app.rb", <<~RUBY
          module TestApp
            class App < Hanami::App
              config.logger.stream = StringIO.new
              config.assets.serve = false
            end
          end
        RUBY

        require "hanami/boot"
      end
    end

    it "doesn't serve static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(404)
    end
  end

  context "when env var is set to true" do
    before do
      with_directory(root) do
        ENV["HANAMI_SERVE_ASSETS"] = "true"
        require "hanami/boot"
      end
    end

    it "serves static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(200)
    end
  end

  context "when env var is set to false" do
    before do
      with_directory(root) do
        ENV["HANAMI_SERVE_ASSETS"] = "false"
        require "hanami/boot"
      end
    end

    it "doesn't serve static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(404)
    end
  end

  context "when Hanami.env is not :development or :test" do
    before do
      with_directory(root) do
        ENV["HANAMI_ENV"] = "production"
        require "hanami/boot"
      end
    end

    it "doesn't serve static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(404)
    end
  end

  context "when Hanami.env is not :development or :test, but env var is set to true" do
    before do
      with_directory(root) do
        ENV["HANAMI_ENV"] = "production"
        ENV["HANAMI_SERVE_ASSETS"] = "true"
        require "hanami/boot"
      end
    end

    it "serves static assets" do
      get "/assets/app.js"

      expect(last_response.status).to eq(200)
    end
  end
end
