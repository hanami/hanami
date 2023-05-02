# frozen_string_literal: true

require "json"
require "rack/test"

RSpec.describe "Web / Rendering errors", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
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

      require "hanami/prepare"
    end
  end

  describe "HTML request" do
    context "error pages present" do
      before do
        with_directory(@dir) do
          write "public/404.html", <<~HTML
            <h1>Not found</h1>
          HTML

          write "public/500.html", <<~HTML
            <h1>Error</h1>
          HTML
        end
      end

      it "responds with the HTML for a 404" do
        get "/foo"

        expect(last_response.status).to eq 404
        expect(last_response.body.strip).to eq "<h1>Not found</h1>"
        expect(last_response.get_header("Content-Type")).to eq "text/html; charset=utf-8"
        expect(last_response.get_header("Content-Length")).to eq "19"
      end

      it "responds with the HTML for a 500" do
        get "/error"

        expect(last_response.status).to eq 500
        expect(last_response.body.strip).to eq "<h1>Error</h1>"
        expect(last_response.get_header("Content-Type")).to eq "text/html; charset=utf-8"
        expect(last_response.get_header("Content-Length")).to eq "15"
      end
    end

    context "error pages missing" do
      it "responds with default text for a 404" do
        get "/foo"

        expect(last_response.status).to eq 404
        expect(last_response.body.strip).to eq "Not Found"
        expect(last_response.get_header("Content-Type")).to eq "text/html; charset=utf-8"
        expect(last_response.get_header("Content-Length")).to eq "9"
      end

      it "responds with default text for a 500" do
        get "/error"

        expect(last_response.status).to eq 500
        expect(last_response.body.strip).to eq "Internal Server Error"
        expect(last_response.get_header("Content-Type")).to eq "text/html; charset=utf-8"
        expect(last_response.get_header("Content-Length")).to eq "21"
      end
    end
  end

  describe "JSON request" do
    it "renders a JSON response for a 404" do
      get "/foo", {}, "HTTP_ACCEPT" => "application/json"

      expect(last_response.status).to eq 404
      expect(last_response.body.strip).to eq %({"status":404,"error":"Not Found"})
      expect(last_response.get_header("Content-Type")).to eq "application/json; charset=utf-8"
      expect(last_response.get_header("Content-Length")).to eq "34"
    end

    it "renders a JSON response for a 500" do
      get "/error", {}, "HTTP_ACCEPT" => "application/json"

      expect(last_response.status).to eq 500
      expect(last_response.body.strip).to eq %({"status":500,"error":"Internal Server Error"})
      expect(last_response.get_header("Content-Type")).to eq "application/json; charset=utf-8"
      expect(last_response.get_header("Content-Length")).to eq "46"
    end
  end
end
