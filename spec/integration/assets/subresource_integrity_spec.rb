RSpec.describe "assets", type: :cli do
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
        RSpec::Support::Env['DATABASE_URL'] = "file://#{Pathname.new('db').join('bookshelf')}"

        hanami "assets precompile"

        expect("public/assets.json").to have_file_content <<-EOF
{"/assets/application.css":{"target":"/assets/application-068e7d97b3671a14824bc20437ac5d06.css","sri":["sha256-cHgODQTP2nNk9ER+ViDGp+lC+ddHRmuLgJk05glJ4+w=","sha512-TDyxo1Ow7UjBib6ykALJh7J1OHEcE0yX4X21s1714ZBAhwdOz7k9t8+QQDAwWAmeH97bNaZGY7oTfVrwyTQ3cw=="]},"/assets/favicon.ico":{"target":"/assets/favicon-2d931609a81d94071c81890f77209101.ico","sri":["sha256-QxGPbQhTL64Lp6vYed7gabWjwB7Uhxkiztdj7LCU23A=","sha512-riH2RZwaTbMOmvfrUcpRWMQORhX9Bz9PLfENwDWm93wD+ESkaIUiYqDl+NShF0hja4L67lTbMglW8lUSmF3Tsg=="]}}
EOF

        server do
          visit '/'
          expect(page.body).to include(%(<link href="/assets/application-068e7d97b3671a14824bc20437ac5d06.css" type="text/css" rel="stylesheet" integrity="sha256-cHgODQTP2nNk9ER+ViDGp+lC+ddHRmuLgJk05glJ4+w= sha512-TDyxo1Ow7UjBib6ykALJh7J1OHEcE0yX4X21s1714ZBAhwdOz7k9t8+QQDAwWAmeH97bNaZGY7oTfVrwyTQ3cw==" crossorigin="anonymous">))
        end
      end
    end
  end
end
