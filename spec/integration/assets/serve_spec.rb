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
          expect(page.body).to include(%(body {\n  font: 100% Helvetica, sans-serif; }\n))
        end
      end
    end

    it "serve assets with prefixes" do
      with_project do
        generate "action web home#index --url=/"

        replace(
          "apps/web/application.rb",
          "# Specify sources for assets",
          "prefix '/library/assets'\n# Specify sources for assets"
        )

        replace(
          "apps/web/config/routes.rb",
          "/",
          "namespace :library { get '/', to: 'home#index' }"
        )

        write "apps/web/assets/javascripts/application.js", <<-EOF
document.addEventListener(
  "DOMContentLoaded",
  function(event) {
    var body = document.getElementsByTagName('body')[0];
    body.innerText = "Javascript asset loaded.";
  }
);
EOF

        rewrite "apps/web/templates/application.html.erb", <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Web</title>
    <%= javascript 'application' %>
    <%= favicon %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
EOF

        hanami "assets precompile"

        server do
          visit "/library"

          expect(page).to have_content("Javascript asset loaded.")
          expect(page.body).to include(%(<script src="/library/assets/application.js" type="text/javascript"></script>))
        end
      end
    end
  end
end
