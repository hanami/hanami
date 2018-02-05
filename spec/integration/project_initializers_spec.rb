RSpec.describe "Project initializers", type: :integration do
  it "mounts Rack middleware" do
    with_project("project_initializers", gems: ['i18n']) do
      write "config/locales/en.yml", <<-EOF
en:
  greeting: "Welcome stranger"
EOF

      write "config/initializers/i18n.rb", <<-EOF
require 'i18n'
I18n.load_path = Dir['config/locales/*.yml']
I18n.backend.load_translations
EOF

      generate "action web home#index --url=/"
      rewrite "apps/web/views/home/index.rb", <<-EOF
module Web::Views::Home
  class Index
    include Web::View

    def greeting
      I18n.t(:greeting)
    end
  end
end
EOF

      rewrite "apps/web/templates/home/index.html.erb", <<-EOF
<h1><%= greeting%></h1>
EOF
      server do
        get '/'

        expect(last_response.body).to include("Welcome stranger")
      end
    end
  end
end
