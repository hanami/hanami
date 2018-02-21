require 'json'

RSpec.describe "assets", type: :integration do
  describe "subresource integrity" do
    it "precompiles assets with checksums calculated with given algorithms" do
      with_project do
        generate "action web home#index --url=/"

        write "apps/web/assets/javascripts/application.css", <<-EOF
body { font: Helvetica; }
EOF
        rewrite "apps/web/templates/application.html.erb", <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Web</title>
    <%= favicon %>
    <%= stylesheet 'application' %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
EOF

        replace "apps/web/application.rb", "subresource_integrity :sha256", "subresource_integrity :sha256, :sha512"

        #
        # Precompile
        #
        RSpec::Support::Env['HANAMI_ENV'] = 'production'
        # FIXME: database connection shouldn't be required for `assets precompile`
        RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
        RSpec::Support::Env['SMTP_HOST'] = 'localhost'
        RSpec::Support::Env['SMTP_PORT'] = '25'

        hanami "assets precompile"

        manifest = File.read("public/assets.json")
        expect(JSON.parse(manifest)).to be_kind_of(Hash) # assert it's a well-formed JSON

        expect(manifest).to include(%("/assets/application.css":{"target":"/assets/application-068e7d97b3671a14824bc20437ac5d06.css","sri":["sha256-cHgODQTP2nNk9ER+ViDGp+lC+ddHRmuLgJk05glJ4+w=","sha512-TDyxo1Ow7UjBib6ykALJh7J1OHEcE0yX4X21s1714ZBAhwdOz7k9t8+QQDAwWAmeH97bNaZGY7oTfVrwyTQ3cw=="]}))
        expect(manifest).to include(%("/assets/favicon.ico":{"target":"/assets/favicon-b0979f93c7f7246ac70949a80f7cbdfd.ico","sri":["sha256-PLEDhpDsTBpxl1KtXjzBjg+PUG67zpf05B1z2db4iJU=","sha512-9NvaW7aVAywbLPPi3fw5s4wtWwd37i8VpzgfEo9uCOyr/mDT2dbYJtGNjfTJa4R8TOw69yHr4NhazPQsLt1WHw=="]}))

        server do
          visit '/'
          expect(page.body).to include(%(<link href="/assets/application-068e7d97b3671a14824bc20437ac5d06.css" type="text/css" rel="stylesheet" integrity="sha256-cHgODQTP2nNk9ER+ViDGp+lC+ddHRmuLgJk05glJ4+w= sha512-TDyxo1Ow7UjBib6ykALJh7J1OHEcE0yX4X21s1714ZBAhwdOz7k9t8+QQDAwWAmeH97bNaZGY7oTfVrwyTQ3cw==" crossorigin="anonymous">))
        end
      end
    end
  end
end
