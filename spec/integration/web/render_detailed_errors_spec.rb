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

  # These assert against the page's `data-webconsole-*` hooks rather than its markup, so that
  # restyling the error page does not break this spec.
  describe "HTML request" do
    it "renders a detailed HTML error page" do
      get "/error", {}, "HTTP_ACCEPT" => "text/html"

      expect(last_response.status).to eq 500

      html = Capybara.string(last_response.body)
      expect(html).to have_selector("[data-webconsole-exception-class]", text: "RuntimeError")
      expect(html).to have_selector("[data-webconsole-request-summary]", text: "/error")
      expect(html).to have_selector(
        "[data-webconsole-frame-kind='app']", text: "app/actions/error.rb"
      )
    end

    it "renders a detailed HTML error page and returns a 404 status for a not found error" do
      get "/__not_found__", {}, "HTTP_ACCEPT" => "text/html"

      expect(last_response.status).to eq 404

      html = Capybara.string(last_response.body)
      expect(html).to have_selector(
        "[data-webconsole-exception-class]", text: "Hanami::Router::NotFoundError"
      )
    end
  end

  describe "Other request types" do
    it "renders a detailed error page in text" do
      get "/error", {}, "HTTP_ACCEPT" => "text/plain"

      expect(last_response.status).to eq 500
      expect(last_response.headers["content-type"]).to include "text/plain"

      expect(last_response.body).to include "## RuntimeError"
      expect(last_response.body).to match %r{### Backtrace.+app/actions/error\.rb}m
    end

    it "renders a detailed error page as JSON" do
      get "/error", {}, "HTTP_ACCEPT" => "application/json"

      expect(last_response.status).to eq 500
      expect(last_response.headers["content-type"]).to include "application/json"

      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq "RuntimeError"
      expect(body["status"]).to eq 500
      expect(body["backtrace"].join("\n")).to include "app/actions/error.rb"
    end

    it "renders a detailed error page in text and returns a 404 status for a not found error" do
      get "/__not_found__", {}, "HTTP_ACCEPT" => "text/plain"

      expect(last_response.status).to eq 404

      expect(last_response.body).to include "## Hanami::Router::NotFoundError"
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
