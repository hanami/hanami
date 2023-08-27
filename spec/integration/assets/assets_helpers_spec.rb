# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Assets / Helpers test", :app_integration, :assets_integration do
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
        <%= javascript_tag("app") %>
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

  it "registers assets in container" do
    require "hanami/assets/precompiler"
    precompiler = Hanami::Assets::Precompiler.new(config: Hanami.app.config.assets)

    with_directory(root) do
      with_retry(Hanami::Assets::PrecompileError) do
        precompiler.call
      end
    end

    output = TestApp::App["views.posts.show"].call.to_s.strip
    expect(output).to match(%(script))
  end
end
