# frozen_string_literal: true

RSpec.describe "App view / Helpers / Scope helpers", :app_integration do
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
        <h1><%= format_number(12_345) %></h1>
      ERB
    end

    it "makes default helpers available in templates" do
      output = TestApp::App["views.posts.show"].call.to_s.strip
      expect(output).to eq "<h1>12,345</h1>"
    end
  end

  describe "slice view" do
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
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/posts/show.html.erb", <<~ERB
        <h1><%= format_number(12_345) %></h1>
      ERB
    end

    it "makes default helpers available in templates" do
      output = Main::Slice["views.posts.show"].call.to_s.strip
      expect(output).to eq "<h1>12,345</h1>"
    end
  end
end
