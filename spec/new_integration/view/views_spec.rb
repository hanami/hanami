# frozen_string_literal: true

RSpec.describe "Hanami view integration", :application_integration do
  specify "Views take their configuration from their slice in which they are defined" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/main/view.rb", <<~RUBY
        require "hanami/view"

        module Main
          class View < Hanami::View
          end
        end
      RUBY

      write "slices/main/lib/main/views/test_view.rb", <<~RUBY
        require "main/view"

        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/web/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/web/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/init"

      rendered = Main::Slice["views.test_view"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end

  specify "Views can also take configuration from the application when defined in the top-level application module" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/view.rb", <<~RUBY
        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "lib/test_app/views/test_view.rb", <<~RUBY
        require "test_app/view"

        module TestApp
          module Views
            class TestView < TestApp::View
              expose :name
            end
          end
        end
      RUBY

      write "web/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "web/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/init"

      rendered = TestApp::Application["views.test_view"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end
end
