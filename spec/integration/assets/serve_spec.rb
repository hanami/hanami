RSpec.describe "assets", type: :cli do
  describe "serve" do
    it "compiles and serves assets in development mode" do
      project = "bookshelf_serve_assets"

      with_project(project, gems: ['sass']) do
        generate "action web home#index --url=/"

        write "apps/web/assets/javascripts/application.css.sass", <<-EOF
$font-family: Helvetica, sans-serif

body
  font: 100% $font-family
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

        server do
          visit '/'
          expect(page.body).to include(%(<link href="/assets/application.css" type="text/css" rel="stylesheet">))

          visit '/assets/application.css'
          expect(page.body).to eq(%(body {\n  font: 100% Helvetica, sans-serif; }\n))
        end
      end
    end
  end
end
