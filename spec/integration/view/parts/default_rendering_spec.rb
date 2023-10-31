# frozen_string_literal: true

RSpec.describe "App view / Parts / Default rendering", :app_integration do
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

      write "app/views/part.rb", <<~RUBY
        # auto_register: false

        module TestApp
          module Views
            class Part < Hanami::View::Part
            end
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app part" do
    def before_prepare
      write "app/views/helpers.rb", <<~RUBY
        # auto_register: false

        module TestApp
          module Views
            module Helpers
              def app_screaming_snake_case(str)
                _context.inflector
                  .underscore(str)
                  .gsub(/\s+/, "_")
                  .upcase + "!"
              end
            end
          end
        end
      RUBY
      write "app/views/parts/post.rb", <<~RUBY
        # auto_register: false

        module TestApp
          module Views
            module Parts
              class Post < TestApp::Views::Part
                def title_tag
                  helpers.tag.h1(helpers.app_screaming_snake_case(value.title))
                end
              end
            end
          end
        end
      RUBY
    end

    it "provides a default rendering from the app" do
      post = Struct.new(:title).new("Hello world")
      part = TestApp::Views::Parts::Post.new(value: post)

      expect(part.title_tag).to eq "<h1>HELLO_WORLD!</h1>"
    end
  end

  describe "slice part" do
    def before_prepare
      write "slices/main/views/helpers.rb", <<~RUBY
        # auto_register: false

        module Main
          module Views
            module Helpers
              def slice_screaming_snake_case(str)
                _context.inflector
                  .underscore(str)
                  .gsub(/\s+/, "_")
                  .upcase + "!"
              end
            end
          end
        end
      RUBY

      write "slices/main/views/part.rb", <<~RUBY
        # auto_register: false

        module Main
          module Views
            class Part < TestApp::View::Part
            end
          end
        end
      RUBY

      write "slices/main/views/parts/post.rb", <<~RUBY
        # auto_register: false

        module Main
          module Views
            module Parts
              class Post < Main::Views::Part
                def title_tag
                  helpers.tag.h1(helpers.slice_screaming_snake_case(value.title))
                end
              end
            end
          end
        end
      RUBY
    end

    it "provides a default rendering from the app" do
      post = Struct.new(:title).new("Hello world")
      part = Main::Views::Parts::Post.new(value: post)

      expect(part.title_tag).to eq "<h1>HELLO_WORLD!</h1>"
    end
  end
end
