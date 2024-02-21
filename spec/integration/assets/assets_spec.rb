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
        <%= stylesheet_tag("app") %>
        <%= javascript_tag("app") %>
      ERB

      write "app/assets/js/app.ts", <<~TS
        import "../css/app.css";

        console.log("Hello from index.ts");
      TS

      write "app/assets/css/app.css", <<~CSS
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

    expect(output).to match(%r{<link href="/assets/app-[A-Z0-9]{8}.css" type="text/css" rel="stylesheet">})
    expect(output).to match(%r{<script src="/assets/app-[A-Z0-9]{8}.js" type="text/javascript"></script>})

    assets = Hanami.app["assets"]

    expect(assets["app.css"].to_s).to match(%r{/assets/app-[A-Z0-9]{8}.css})
    expect(assets["app.js"].to_s).to match(%r{/assets/app-[A-Z0-9]{8}.js})
  end

  describe "slice with assets" do
    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY

      write "slices/main/views/posts/show.rb", <<~RUBY
        module Main
          module Views
            module Posts
              class Show < Main::View
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/posts/show.html.erb", <<~ERB
        <%= stylesheet_tag("app") %>
        <%= javascript_tag("app") %>
      ERB

      write "slices/main/assets/js/app.ts", <<~TS
        import "../css/app.css";

        console.log("Hello from main slice index.ts");
      TS

      write "slices/main/assets/css/app.css", <<~CSS
        .btn {
          background: #f00;
        }
      CSS
    end

    specify "the slice's assets are available in its own and distinct `assets` component" do
      compile_assets!

      output = Main::Slice["views.posts.show"].call.to_s

      expect(output).to match(%r{<link href="/assets/_main/app-[A-Z0-9]{8}.css" type="text/css" rel="stylesheet">})
      expect(output).to match(%r{<script src="/assets/_main/app-[A-Z0-9]{8}.js" type="text/javascript"></script>})

      assets = Main::Slice["assets"]

      expect(assets["app.css"].to_s).to match(%r{/assets/_main/app-[A-Z0-9]{8}.css})
      expect(assets["app.js"].to_s).to match(%r{/assets/_main/app-[A-Z0-9]{8}.js})
    end
  end

  describe "slice without assets" do
    def before_prepare
      write "slices/main/.keep", ""
    end

    it "does not have an assets component" do
      expect(Main::Slice.key?("assets")).to be false
    end
  end
end
