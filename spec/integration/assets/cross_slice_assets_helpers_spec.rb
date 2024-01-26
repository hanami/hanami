# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Cross-slice assets via helpers", :app_integration do
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

      write "config/slices/admin.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            # TODO: we should update `import` to make importing from the app nicer
            # TODO: this test failed when I tried doing `as: "app"` (string instead of symbol); fix this in dry-system
            import keys: ["assets"], from: Hanami.app.container, as: :app
          end
        end
      RUBY

      write "config/assets.js", <<~JS
        import * as assets from "hanami-assets";
        await assets.run();
      JS

      write "package.json", <<~JSON
        {
          "type": "module"
        }
      JSON

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
            config.layout = nil
          end
        end
      RUBY

      write "app/assets/js/app.ts", <<~TS
        import "../css/app.css";

        console.log("Hello from index.ts");
      TS

      write "app/assets/css/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS

      write "slices/admin/assets/js/app.ts", <<~TS
        import "../css/app.css";

        console.log("Hello from admin's index.ts");
      TS

      write "slices/admin/assets/css/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS

      write "slices/admin/view.rb", <<~RUBY
        # auto_register: false

        module Admin
          class View < TestApp::View
          end
        end
      RUBY

      write "slices/admin/views/posts/show.rb", <<~RUBY
        module Admin
          module Views
            module Posts
              class Show < Admin::View
              end
            end
          end
        end
      RUBY

      write "slices/admin/views/context.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module Admin
          module Views
            class Context < Hanami::View::Context
              include Deps[app_assets: "app.assets"]
            end
          end
        end
      RUBY

      write "slices/admin/templates/posts/show.html.erb", <<~ERB
        <%= stylesheet_tag(app_assets["app.css"]) %>
        <%= javascript_tag(app_assets["app.js"]) %>
      ERB

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  specify "assets are available in helpers and in `assets` component" do
    compile_assets!

    output = Admin::Slice["views.posts.show"].call.to_s

    expect(output).to match(%r{<link href="/assets/app-[A-Z0-9]{8}.css" type="text/css" rel="stylesheet">})
    expect(output).to match(%r{<script src="/assets/app-[A-Z0-9]{8}.js" type="text/javascript"></script>})
  end
end
