# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Assets", :app_integration do
  include Rack::Test::Methods
  let(:app) { Hanami.app }
  let(:root) { make_tmp_directory }

  before do
    with_directory(root) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            get "posts/:id/edit", to: "posts.edit"
            put "posts/:id", to: "posts.update"
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        require "hanami/action"

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
            config.layout = nil
          end
        end
      RUBY

      write "app/views/posts/show.rb", <<~RUBY
        module TestApp
          module Views
            module Posts
              class Show < TestApp::View
              end
            end
          end
        end
      RUBY

      write "app/templates/posts/show.html.erb", <<~ERB
        <%= stylesheet_link_tag("app") %>
        <%= css("app") %>
        <%= javascript_tag("app") %>
        <%= js("app") %>
      ERB

      write "app/assets/javascripts/app.ts", <<~TS
        import "../stylesheets/app.css";

        console.log("Hello from index.ts");
      TS

      write "app/assets/stylesheets/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  specify "assets are available in helpers and in `assets` component" do
    compile_assets!

    output = Hanami.app["views.posts.show"].call.to_s

    expect(output).to eq <<~HTML
      <link href="/assets/app-N47SR66M.css" type="text/css" rel="stylesheet">
      <link href="/assets/app-N47SR66M.css" type="text/css" rel="stylesheet">
      <script src="/assets/app-A5GJ52WC.js" type="text/javascript"></script>
      <script src="/assets/app-A5GJ52WC.js" type="text/javascript"></script>
    HTML

    assets = Hanami.app["assets"]

    expect(assets["app.css"].to_s).to eq "/assets/app-N47SR66M.css"
    expect(assets["app.js"].to_s).to eq "/assets/app-A5GJ52WC.js"
  end
end
