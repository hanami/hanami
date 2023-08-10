# frozen_string_literal: true

require "rack/test"
require "stringio"
require "fileutils"

RSpec.describe "Assets / Base test", :app_integration, :assets_integration do
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
    precompiler = Hanami::Assets::Precompiler.new(configuration: Hanami.app.config.assets)

    with_directory(root) do
      with_retry(Hanami::Assets::PrecompileError) do
        precompiler.call
      end
    end

    assets = Hanami.app["assets"]
    expect(assets.js("app")).to match("script")
  end

  # it "uses the value from the view's locals" do
  #   get "/posts/123/edit"

  #   html = Capybara.string(last_response.body)

  #   title_field = html.find("input[name='post[title]']")
  #   expect(title_field.value).to eq "Hello <world>"

  #   body_field = html.find("textarea[name='post[body]']")
  #   expect(body_field.value).to eq "This is the post."
  # end

  # it "prefers the values from the request params" do
  #   put "/posts/123", post: {title: "", body: "This is the UPDATED post."}

  #   html = Capybara.string(last_response.body)

  #   title_field = html.find("input[name='post[title]']")
  #   expect(title_field.value).to eq ""

  #   body_field = html.find("textarea[name='post[body]']")
  #   expect(body_field.value).to eq "This is the UPDATED post."
  # end

  # context "sessions enabled" do
  #   def before_prepare
  #     write "config/app.rb", <<~RUBY
  #       module TestApp
  #         class App < Hanami::App
  #           config.logger.stream = StringIO.new
  #           config.actions.sessions = :cookie, {secret: "xyz"}
  #         end
  #       end
  #     RUBY
  #   end

  #   it "inserts a CSRF token field" do
  #     get "/posts/123/edit"

  #     html = Capybara.string(last_response.body)

  #     csrf_field = html.find("input[type='hidden'][name='_csrf_token']", visible: false)
  #     expect(csrf_field.value).to match(/[a-z0-9]{10,}/i)
  #   end
  # end
end
