RSpec.describe "assets", type: :cli do
  describe "digest mode" do
    it "servers assets with digest url" do
      with_project do
        generate "action web home#index --url=/"

        write "apps/web/assets/javascripts/application.css", <<-EOF
body { color: #333 };
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
        #
        # Precompile
        #
        RSpec::Support::Env['HANAMI_ENV']   = 'production'
        RSpec::Support::Env['DATABASE_URL'] = "file://#{Pathname.new('db').join('bookshelf')}"
        hanami "assets precompile"

        server do
          visit '/'

          expect(page.body).to include(%(<link href="/assets/application-5df86b4e9cbd733a027762b2f6bf8693.css" type="text/css" rel="stylesheet" integrity="sha256-LxaTcWkL8TAWFQWeHJ7OqoSoEXXaYapNIS+TCvGNf48=" crossorigin="anonymous">))
        end
      end
    end
  end
end
