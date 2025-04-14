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
            <%= stylesheet_tag "app" %>
          </head>
          <body>
            <style nonce="<%= content_security_policy_nonce %>"></style>
            <%= javascript_tag "app" %>
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
              config.middleware.use Hanami::Middleware::ContentSecurityPolicyNonce
              config.actions.content_security_policy[:script_src] = "'self' 'nonce'"

              config.logger.stream = File::NULL
            end
          end
        RUBY
      end

      it "sets hanami.content_security_policy_nonce in Rack env" do
        get "/index"

        expect(last_request.env["hanami.content_security_policy_nonce"]).to match(/\A[A-Za-z0-9\-_]{22}\z/)
      end

      it "substitutes 'nonce' in the CSP header" do
        get "/index"
        nonce = last_request.env["hanami.content_security_policy_nonce"]

        expect(last_response.get_header("Content-Security-Policy")).to match(/script-src 'self' 'nonce-#{nonce}'/)
      end

      it "enables the content_security_policy_nonce helper" do
        get "/index"
        nonce = last_request.env["hanami.content_security_policy_nonce"]

        expect(last_response.body).to match(/<style nonce="#{Regexp.escape(nonce)}">/)
      end

      it "adds the nonce attribute to the javascript_tag helper" do
        get "/index"
        nonce = last_request.env["hanami.content_security_policy_nonce"]

        expect(last_response.body).to match(/<script[^>]*\s+nonce="#{Regexp.escape(nonce)}"/)
      end

      it "adds the nonce attribute to the stylesheet_tag helper" do
        get "/index"
        nonce = last_request.env["hanami.content_security_policy_nonce"]

        expect(last_response.body).to match(/<link[^>]*\s+nonce="#{Regexp.escape(nonce)}"/)
      end
    end

    context "CSP disabled" do
      def before_prepare
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.middleware.use Hanami::Middleware::ContentSecurityPolicyNonce
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

      it "doesn't add the nonce attribute to the javascript_tag helper" do
        get "/index"

        expect(last_response.body).to match(/<script(?![^>]*\s+nonce=)/)
      end

      it "doesn't add the nonce attribute to the stylesheet_tag helper" do
        get "/index"

        expect(last_response.body).to match(/<link(?![^>]*\s+nonce=)/)
      end
    end
  end
end
