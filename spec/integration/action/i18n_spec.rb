# frozen_string_literal: true

require "date"

RSpec.describe "App action / I18n", :app_integration do
  describe "translate and localize in an app-level action" do
    specify "delegates to the app slice's i18n backend" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App; end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            messages:
              welcome: "Welcome to Hanami"
            greeting_html: "Hello, <strong>%{name}</strong>!"
        YAML

        write "app/action.rb", <<~RUBY
          # auto_register: false

          module TestApp
            class Action < Hanami::Action; end
          end
        RUBY

        write "app/actions/home/index.rb", <<~RUBY
          module TestApp
            module Actions
              module Home
                class Index < TestApp::Action
                  def handle(req, res)
                    res.body = [
                      t("messages.welcome"),
                      t("greeting_html", name: "<Alice>"),
                      l(Date.new(2026, 5, 11), format: :short)
                    ].join("|")
                  end
                end
              end
            end
          end
        RUBY

        require "hanami/prepare"

        response = TestApp::App["actions.home.index"].call({})
        expect(response.body).to eq [
          "Welcome to Hanami|Hello, <strong>&lt;Alice&gt;</strong>!|11 May"
        ]
      end
    end
  end

  describe "relative key lookup" do
    specify "expands a leading-dot key against the action's name" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App; end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            posts:
              show:
                title: "Post title"
        YAML

        write "app/action.rb", <<~RUBY
          # auto_register: false

          module TestApp
            class Action < Hanami::Action; end
          end
        RUBY

        write "app/actions/posts/show.rb", <<~RUBY
          module TestApp
            module Actions
              module Posts
                class Show < TestApp::Action
                  def handle(req, res)
                    res.body = t(".title")
                  end
                end
              end
            end
          end
        RUBY

        require "hanami/prepare"

        response = TestApp::App["actions.posts.show"].call({})
        expect(response.body).to eq ["Post title"]
      end
    end
  end

  describe "slice isolation" do
    specify "each slice's action resolves keys against its own backend" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App; end
          end
        RUBY

        write "app/action.rb", <<~RUBY
          # auto_register: false

          module TestApp
            class Action < Hanami::Action; end
          end
        RUBY

        write "slices/main/config/i18n/en.yml", <<~YAML
          en:
            posts:
              show:
                title: "Main title"
        YAML

        write "slices/admin/config/i18n/en.yml", <<~YAML
          en:
            posts:
              show:
                title: "Admin title"
        YAML

        write "slices/main/action.rb", <<~RUBY
          module Main
            class Action < TestApp::Action; end
          end
        RUBY

        write "slices/admin/action.rb", <<~RUBY
          module Admin
            class Action < TestApp::Action; end
          end
        RUBY

        write "slices/main/actions/posts/show.rb", <<~RUBY
          module Main
            module Actions
              module Posts
                class Show < Main::Action
                  def handle(req, res)
                    res.body = t(".title")
                  end
                end
              end
            end
          end
        RUBY

        write "slices/admin/actions/posts/show.rb", <<~RUBY
          module Admin
            module Actions
              module Posts
                class Show < Admin::Action
                  def handle(req, res)
                    res.body = t(".title")
                  end
                end
              end
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Main::Slice["actions.posts.show"].call({}).body).to eq ["Main title"]
        expect(Admin::Slice["actions.posts.show"].call({}).body).to eq ["Admin title"]
      end
    end
  end
end
