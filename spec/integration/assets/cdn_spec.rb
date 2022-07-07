# frozen_string_literal: true

RSpec.describe "assets", type: :integration do
  describe "CDN mode" do
    it "servers assets with CDN url" do
      with_project do
        generate "action web home#index --url=/"

        write "apps/web/assets/javascripts/app.css", <<~EOF
          body { color: #333 };
        EOF
        rewrite "apps/web/templates/app.html.erb", <<~EOF
          <!DOCTYPE html>
          <html>
            <head>
              <title>Web</title>
              <%= favicon %>
              <%= stylesheet 'app' %>
            </head>
            <body>
              <%= yield %>
            </body>
          </html>
        EOF

        replace_last "apps/web/app.rb", "# scheme 'https'",           "scheme 'https'"
        replace      "apps/web/app.rb", "# host   'cdn.example.org'", "host   'cdn.example.org'"
        replace_last "apps/web/app.rb", "# port   443",               "port   443"

        #
        # Precompile
        #
        RSpec::Support::Env["HANAMI_ENV"]   = "production"
        RSpec::Support::Env["DATABASE_URL"] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
        RSpec::Support::Env["SMTP_HOST"]    = "localhost"
        RSpec::Support::Env["SMTP_PORT"]    = "25"

        hanami "assets precompile"

        server do
          visit "/"

          expect(page.body).to include(%(<link href="https://cdn.example.org/assets/app-5df86b4e9cbd733a027762b2f6bf8693.css" type="text/css" rel="stylesheet" integrity="sha256-LxaTcWkL8TAWFQWeHJ7OqoSoEXXaYapNIS+TCvGNf48=" crossorigin="anonymous">))
        end
      end
    end
  end
end
