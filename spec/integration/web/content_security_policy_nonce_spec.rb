# frozen_string_literal: true

require "rack/test"

RSpec.describe "Web / Content security policy nonce", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            get "index", to: "index"
          end
        end
      RUBY

      write "app/actions/index.rb", <<~RUBY
        module TestApp
          module Actions
            class Index < Hanami::Action
            end
          end
        end
      RUBY

      write "app/views/index.rb", <<~RUBY
        module TestApp
          module Views
            class Index < Hanami::View
              config.layout = false
            end
          end
        end
      RUBY

      write "app/templates/index.html.erb", <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <%= stylesheet_tag "app", class: "nonce-true", nonce: true %>
            <%= stylesheet_tag "app", class: "nonce-false", nonce: false %>
            <%= stylesheet_tag "app", class: "nonce-explicit", nonce: "explicit" %>
            <%= stylesheet_tag "app", class: "nonce-generated" %>
            <%= stylesheet_tag "https://example.com/app.css", class: "nonce-absolute" %>
          </head>
          <body>
            <style nonce="<%= content_security_policy_nonce %>"></style>
            <%= javascript_tag "app", class: "nonce-true", nonce: true %>
            <%= javascript_tag "app", class: "nonce-false", nonce: false %>
            <%= javascript_tag "app", class: "nonce-explicit", nonce: "explicit" %>
            <%= javascript_tag "app", class: "nonce-generated" %>
            <%= javascript_tag "https://example.com/app.js", class: "nonce-absolute" %>
          </body>
        </html>
      HTML

      write "package.json", <<~JSON
        {
          "type": "module"
        }
      JSON

      write "config/assets.js", <<~JS
        import * as assets from "hanami-assets";
        await assets.run();
      JS

      write "app/assets/js/app.js", <<~JS
        import "../css/app.css";
      JS

      write "app/assets/css/app.css", ""

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
      compile_assets!
    end
  end

  describe "HTML request" do
    context "CSP enabled" do
      def before_prepare
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.actions.content_security_policy[:script_src] = "'self' 'nonce'"

              config.logger.stream = File::NULL
            end
          end
        RUBY
      end

      it "sets unique and per-request hanami.content_security_policy_nonce in Rack env" do
        previous_nonces = []
        3.times do
          get "/index"
          nonce = last_request.env["hanami.content_security_policy_nonce"]

          expect(nonce).to match(/\A[A-Za-z0-9\-_]{22}\z/)
          expect(previous_nonces).not_to include nonce

          previous_nonces << nonce
        end
      end

      it "accepts custom nonce generator proc without arguments" do
        Hanami.app.config.actions.content_security_policy_nonce_generator = -> { "foobar" }

        get "/index"

        expect(last_request.env["hanami.content_security_policy_nonce"]).to eql("foobar")
      end

      it "accepts custom nonce generator proc with Rack request as argument" do
        Hanami.app.config.actions.content_security_policy_nonce_generator = ->(request) { request }

        get "/index"

        expect(last_request.env["hanami.content_security_policy_nonce"]).to be_a(Rack::Request)
      end

      it "substitutes 'nonce' in the CSP header" do
        get "/index"
        nonce = last_request.env["hanami.content_security_policy_nonce"]

        expect(last_response.get_header("Content-Security-Policy")).to match(/script-src 'self' 'nonce-#{nonce}'/)
      end

      it "behaves the same with explicitly added middleware" do
        Hanami.app.config.middleware.use Hanami::Middleware::ContentSecurityPolicyNonce
        get "/index"

        expect(last_request.env["hanami.content_security_policy_nonce"]).to match(/\A[A-Za-z0-9\-_]{22}\z/)
      end

      describe "content_security_policy_nonce" do
        it "renders the current nonce" do
          get "/index"
          nonce = last_request.env["hanami.content_security_policy_nonce"]

          expect(last_response.body).to include(%(<style nonce="#{nonce}">))
        end
      end

      describe "stylesheet_tag" do
        it "renders the correct nonce unless remote URL or nonce set to false" do
          get "/index"
          nonce = last_request.env["hanami.content_security_policy_nonce"]

          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" nonce="#{nonce}" class="nonce-true">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" class="nonce-false">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" nonce="explicit" class="nonce-explicit">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" nonce="#{nonce}" class="nonce-generated">))
          expect(last_response.body).to include(%(<link href="https://example.com/app.css" type="text/css" rel="stylesheet" class="nonce-absolute">))
        end
      end

      describe "javascript_tag" do
        it "renders the correct nonce unless remote URL or nonce set to false" do
          get "/index"
          nonce = last_request.env["hanami.content_security_policy_nonce"]

          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" nonce="#{nonce}" class="nonce-true"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" class="nonce-false"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" nonce="explicit" class="nonce-explicit"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" nonce="#{nonce}" class="nonce-generated"></script>))
          expect(last_response.body).to include(%(<script src="https://example.com/app.js" type="text/javascript" class="nonce-absolute"></script>))
        end
      end
    end

    context "CSP disabled" do
      def before_prepare
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.actions.content_security_policy = false

              config.logger.stream = File::NULL
            end
          end
        RUBY
      end

      it "does not set hanami.content_security_policy_nonce in Rack env" do
        get "/index"

        expect(last_request.env).to_not have_key "hanami.content_security_policy_nonce"
      end

      it "does not produce a CSP header" do
        get "/index"

        expect(last_response.headers).to_not have_key "Content-Security-Policy"
      end

      it "disables the content_security_policy_nonce helper" do
        get "/index"

        expect(last_response.body).to match(/<style nonce="">/)
      end

      it "behaves the same with explicitly added middleware" do
        Hanami.app.config.middleware.use Hanami::Middleware::ContentSecurityPolicyNonce
        get "/index"

        expect(last_response.headers).to_not have_key "Content-Security-Policy"
      end

      describe "content_security_policy_nonce" do
        it "renders nothing" do
          get "/index"

          expect(last_response.body).to include(%(<style nonce="">))
        end
      end

      describe "stylesheet_tag" do
        it "renders the correct explicit nonce only" do
          get "/index"

          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" class="nonce-true">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" class="nonce-false">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" nonce="explicit" class="nonce-explicit">))
          expect(last_response.body).to include(%(<link href="/assets/app-KUHJPSX7.css" type="text/css" rel="stylesheet" class="nonce-generated">))
          expect(last_response.body).to include(%(<link href="https://example.com/app.css" type="text/css" rel="stylesheet" class="nonce-absolute">))
        end
      end

      describe "javascript_tag" do
        it "renders the correct explicit nonce only" do
          get "/index"

          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" class="nonce-true"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" class="nonce-false"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" nonce="explicit" class="nonce-explicit"></script>))
          expect(last_response.body).to include(%(<script src="/assets/app-LSLFPUMX.js" type="text/javascript" class="nonce-generated"></script>))
          expect(last_response.body).to include(%(<script src="https://example.com/app.js" type="text/javascript" class="nonce-absolute"></script>))
        end
      end
    end
  end
end
