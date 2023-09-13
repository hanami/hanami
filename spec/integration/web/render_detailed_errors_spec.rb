# frozen_string_literal: true

require "json"
require "rack/test"

RSpec.describe "Web / Rendering detailed errors", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
            config.render_detailed_errors = true
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            get "error", to: "error"
          end
        end
      RUBY

      write "app/actions/error.rb", <<~RUBY
        module TestApp
          module Actions
            class Error < Hanami::Action
              def handle(*)
                raise "oops"
              end
            end
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "HTML request" do
    it "renders a detailed HTML error page" do
      get "/error", {}, "HTTP_ACCEPT" => "text/html"

      expect(last_response.status).to eq 500

      html = Capybara.string(last_response.body)
      expect(html).to have_selector("header", text: "RuntimeError at /error")
      expect(html).to have_selector("ul.frames li.application", text: "app/actions/error.rb")
    end

    it "renders a detailed HTML error page and returns a 404 status for a not found error" do
      get "/__not_found__", {}, "HTTP_ACCEPT" => "text/html"

      expect(last_response.status).to eq 404

      html = Capybara.string(last_response.body)
      expect(html).to have_selector("header", text: "Hanami::Router::NotFoundError at /__not_found__")
    end
  end

  describe "Other request types" do
    it "renders a detailed error page in text" do
      get "/error", {}, "HTTP_ACCEPT" => "application/json"

      expect(last_response.status).to eq 500

      expect(last_response.body).to include "RuntimeError at /error"
      expect(last_response.body).to match %r{App backtrace.+app/actions/error.rb}m
    end

    it "renders a detailed error page in text and returns a 404 status for a not found error" do
      get "/__not_found__", {}, "HTTP_ACCEPT" => "text/html"

      expect(last_response.status).to eq 404

      expect(last_response.body).to include "Hanami::Router::NotFoundError at /__not_found__"
    end
  end

  describe "render_detailed_errors config disabled" do
    def before_prepare
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
            config.render_detailed_errors = false
          end
        end
      RUBY
    end

    it "raises errors from within the app" do
      expect { get "/error" }.to raise_error(RuntimeError, "oops")
    end
  end
end
