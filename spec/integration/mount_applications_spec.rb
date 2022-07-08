require "resolv-replace"
require "net/http"
require "uri"

RSpec.describe "mount apps", type: :integration do
  before do
    stub_dns_hosts("127.0.0.1 #{host} www.#{host} #{subdomain} localhost")
  end

  let(:host) { "bookshelf.test" }
  let(:subdomain) { "beta.#{host}" }

  context "with apps mounted with path" do
    it "shows welcome page" do
      with_project do
        generate_host_middleware
        generate "app admin"
        generate "app beta"

        replace "config/environment.rb", "Beta::App", %(  mount Beta::App, at: "/", host: "#{subdomain}")

        server do
          # Web
          visit "/"
          expect(page).to have_content("bundle exec hanami generate action web 'home#index' --url=/")

          # Admin
          visit "/admin"
          expect(page).to have_content("bundle exec hanami generate action admin 'home#index' --url=/")
        end
      end
    end
  end

  context "when apps mounted with host: option" do
    it "shows welcome page" do
      with_project do
        generate_host_middleware
        generate "app admin"
        generate "app beta"

        replace "config/environment.rb", "Beta::App", %(  mount Beta::App, at: "/", host: "#{subdomain}")

        port = RSpec::Support::RandomPort.call
        server(port: port) do
          # Beta
          response = raw_http_request("http://#{subdomain}:#{port}")
          expect(response.body).to include("bundle exec hanami generate action beta 'home#index' --url=/")
        end
      end
    end
  end

  private

  def generate_host_middleware
    unshift "config/environment.rb", 'require_relative "./middleware/host"'

    inject_line_after "config/environment.rb", "Hanami.configure", <<-EOL
middleware.use Middleware::Host
EOL

    write "config/middleware/host.rb", <<-EOF
require "uri"

module Middleware
  class Host
    def initialize(app)
      @app = app
    end

    def call(env)
      host = URI.parse(env["REQUEST_URI"]).host
      env["SERVER_NAME"] = host
      env["HTTP_HOST"] = host
      env["HTTP_X_FORWARDED_HOST"] = host

      @app.call(env)
    end
  end
end
EOF
  end

  def raw_http_request(uri)
    Net::HTTP.get_response(URI.parse(uri))
  end
end
