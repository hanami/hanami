# frozen_string_literal: true

RSpec.describe "App view / Helpers / I18n helper", :app_integration do
  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
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

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app view" do
    def before_prepare
      write "config/i18n/en.yml", <<~YAML
        en:
          messages:
            welcome: "Welcome to Hanami"
          greeting_html: "Hello, <strong>%{name}</strong>!"
      YAML

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
        <h1><%= t("messages.welcome") %></h1>
        <p><%= t("greeting_html", name: "<Alice>") %></p>
        <time><%= l(Date.new(2026, 5, 11), format: :short) %></time>
        <span><%= t("missing.key") %></span>
      ERB
    end

    it "makes translate and localize available in templates" do
      output = TestApp::App["views.posts.show"].call.to_s

      expect(output).to include "<h1>Welcome to Hanami</h1>"
      expect(output).to include "<p>Hello, <strong>&lt;Alice&gt;</strong>!</p>"
      expect(output).to include "<time>11 May</time>"
      expect(output).to include %(<span class="translation_missing")
    end
  end

  describe "slice view" do
    def before_prepare
      write "slices/main/config/i18n/en.yml", <<~YAML
        en:
          posts:
            title: "Posts in Main"
      YAML

      write "slices/main/view.rb", <<~RUBY
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
        <h1><%= t("posts.title") %></h1>
        <time><%= l(Date.new(2026, 5, 11), format: :short) %></time>
      ERB
    end

    it "makes translate and localize available in templates" do
      output = Main::Slice["views.posts.show"].call.to_s

      expect(output).to include "<h1>Posts in Main</h1>"
      expect(output).to include "<time>11 May</time>"
    end
  end
end
