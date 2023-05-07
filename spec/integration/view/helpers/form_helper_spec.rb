# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Helpers / FormHelper", :app_integration do
  include Rack::Test::Methods
  let(:app) { Hanami.app }

  before do
    with_directory(make_tmp_directory) do
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

      write "app/actions/posts/edit.rb", <<~RUBY
        module TestApp
          module Actions
            module Posts
              class Edit < TestApp::Action
              end
            end
          end
        end
      RUBY

      write "app/actions/posts/update.rb", <<~RUBY
        module TestApp
          module Actions
            module Posts
              class Update < TestApp::Action
                def handle(request, response)
                  if valid?(request.params[:post])
                    response.redirect_to "/posts/x/edit"
                  else
                    response.render view
                  end
                end

                private

                def valid?(post)
                  post.to_h[:title].to_s.length > 0
                end
              end
            end
          end
        end
      RUBY

      write "app/views/posts/edit.rb", <<~RUBY
        module TestApp
          module Views
            module Posts
              class Edit < TestApp::View
                expose :post do
                  Struct.new(:title, :body).new("Hello <world>", "This is the post.")
                end
              end
            end
          end
        end
      RUBY

      write "app/templates/posts/edit.html.erb", <<~ERB
        <h1>Edit post</h1>

        <%= form_for("/posts") do |f| %>
          <div>
            Title:
            <%= f.text_field "post.title" %>
          </div>
          <div>
            Body:
            <%= f.text_area "post.body" %>
          </div>
        <% end %>
      ERB

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  it "does not have a _csrf_token field when no sessions are configured" do
    get "/posts/123/edit"

    html = Capybara.string(last_response.body)

    expect(html).to have_no_selector("input[type='hidden'][name='_csrf_token']")
  end

  it "uses the value from the view's locals" do
    get "/posts/123/edit"

    html = Capybara.string(last_response.body)

    title_field = html.find("input[name='post[title]']")
    expect(title_field.value).to eq "Hello <world>"

    body_field = html.find("textarea[name='post[body]']")
    expect(body_field.value).to eq "This is the post."
  end

  it "prefers the values from the request params" do
    put "/posts/123", post: {title: "", body: "This is the UPDATED post."}

    html = Capybara.string(last_response.body)

    title_field = html.find("input[name='post[title]']")
    expect(title_field.value).to eq ""

    body_field = html.find("textarea[name='post[body]']")
    expect(body_field.value).to eq "This is the UPDATED post."
  end

  context "sessions enabled" do
    def before_prepare
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.actions.sessions = :cookie, {secret: "xyz"}
          end
        end
      RUBY
    end

    it "inserts a CSRF token field" do
      get "/posts/123/edit"

      html = Capybara.string(last_response.body)

      csrf_field = html.find("input[type='hidden'][name='_csrf_token']", visible: false)
      expect(csrf_field.value).to match(/[a-z0-9]{10,}/i)
    end
  end
end
