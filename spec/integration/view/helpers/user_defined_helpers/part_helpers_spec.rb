# frozen_string_literal: true

require "ostruct"

# rubocop:disable Style/OpenStructUse

RSpec.describe "App view / Helpers / User-defined helpers / Scope helpers", :app_integration do
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

      write "app/views/helpers.rb", <<~'RUBY'
        # auto_register: false

        module TestApp
          module Views
            module Helpers
              def exclaim_from_app(str)
                tag.h1("#{str}! (app #{_context.inflector.pluralize('helper')})")
              end
            end
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app view and parts" do
    def before_prepare
      write "app/views/posts/show.rb", <<~RUBY
        module TestApp
          module Views
            module Posts
              class Show < TestApp::View
                expose :post
              end
            end
          end
        end
      RUBY

      write "app/views/parts/post.rb", <<~RUBY
        module TestApp
          module Views
            module Parts
              class Post < TestApp::Views::Part
                def title
                  helpers.exclaim_from_app(value.title)
                end
              end
            end
          end
        end
      RUBY

      write "app/templates/posts/show.html.erb", <<~ERB
        <%= post.title %>
      ERB
    end

    it "makes user-defined helpers available in parts via a `helpers` object" do
      post = OpenStruct.new(title: "Hello world")
      output = TestApp::App["views.posts.show"].call(post: post).to_s.strip

      expect(output).to eq "<h1>Hello world! (app helpers)</h1>"
    end
  end

  describe "slice view and parts" do
    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        module Main
          class View < TestApp::View
            # FIXME: base slice views should override paths from the base app view
            config.paths = [File.join(File.expand_path(__dir__), "templates")]
          end
        end
      RUBY

      write "slices/main/views/helpers.rb", <<~'RUBY'
        # auto_register: false

        module Main
          module Views
            module Helpers
              def exclaim_from_slice(str)
                tag.h1("#{str}! (slice #{_context.inflector.pluralize('helper')})")
              end
            end
          end
        end
      RUBY

      write "slices/main/views/posts/show.rb", <<~RUBY
        module Main
          module Views
            module Posts
              class Show < Main::View
                expose :post
              end
            end
          end
        end
      RUBY

      write "slices/main/views/parts/post.rb", <<~RUBY
        module Main
          module Views
            module Parts
              class Post < Main::Views::Part
                def title
                  helpers.exclaim_from_slice(value.title)
                end

                def title_from_app
                  helpers.exclaim_from_app(value.title)
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/posts/show.html.erb", <<~ERB
        <%= post.title %>
        <%= post.title_from_app %>
      ERB
    end

    it "makes user-defined helpers (from app as well as slice) available in parts via a `helpers` object" do
      post = OpenStruct.new(title: "Hello world")
      output = Main::Slice["views.posts.show"].call(post: post).to_s

      expect(output).to eq <<~HTML
        <h1>Hello world! (slice helpers)</h1>
        <h1>Hello world! (app helpers)</h1>
      HTML
    end
  end
end

# rubocop:enable Style/OpenStructUse
