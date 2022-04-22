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

      write "slices/main/lib/view.rb", <<~RUBY
        require "hanami/application/view"

        module Main
          class View < Hanami::Application::View
          end
        end
      RUBY

      write "slices/main/lib/views/test_view.rb", <<~RUBY
        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

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

      write "slices/main/lib/view.rb", <<~RUBY
        # auto_register: false
        require "hanami/application/view"

        module Main
          class View < Hanami::Application::View
          end
        end
      RUBY

      write "slices/main/views/test_view.rb", <<~RUBY
        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

      rendered = Main::Slice["views.test_view"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end
end
