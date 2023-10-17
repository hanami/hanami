# frozen_string_literal: true

require "ostruct"

# rubocop:disable Style/OpenStructUse

RSpec.describe "App view / Helpers / Part helpers", :app_integration do
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
                def number
                  helpers.format_number(value.number)
                end
              end
            end
          end
        end
      RUBY

      write "app/templates/posts/show.html.erb", <<~ERB
        <h1><%= post.number %></h1>
      ERB
    end

    it "makes default helpers available in parts" do
      post = OpenStruct.new(number: 12_345)
      output = TestApp::App["views.posts.show"].call(post: post).to_s.strip

      expect(output).to eq "<h1>12,345</h1>"
    end
  end

  describe "slice view and parts" do
    def before_prepare
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
                def number
                  helpers.format_number(value.number)
                end
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/posts/show.html.erb", <<~ERB
        <h1><%= post.number %></h1>
      ERB
    end

    it "makes default helpers available in parts" do
      post = OpenStruct.new(number: 12_345)
      output = Main::Slice["views.posts.show"].call(post: post).to_s.strip

      expect(output).to eq "<h1>12,345</h1>"
    end
  end
end

# rubocop:enable Style/OpenStructUse
