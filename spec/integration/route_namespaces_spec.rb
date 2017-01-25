RSpec.describe 'route namespaces', type: :cli do
  it "can handle asset prefixes" do
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
      write("apps/web/assets/javascripts/application.js", <<~EOF)
        document.addEventListener(
          "DOMContentLoaded",
          function(event) {
            var body = document.getElementsByTagName('body')[0];
            body.innerText = "Javascript asset loaded.";
          }
        );
      EOF

      rewrite("apps/web/templates/application.html.erb", <<~EOF)
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

        expect(last_response.status).to eq(200)
        expect(page).to have_content("Javascript asset loaded.")
        expect(page.body).to include(%(<script src="/library/assets/application.js" type="text/javascript"></script>))
      end
    end
  end
end
