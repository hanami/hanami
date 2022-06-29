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

      write "app/view.rb", <<~RUBY
        # auto_register: false
        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "app/views/users/show.rb", <<~RUBY
        module TestApp
          module Views
            module Users
              class Show < TestApp::View
                expose :name
              end
            end
          end
        end
      RUBY

      write "app/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "app/templates/users/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

      rendered = TestApp::Application["views.users.show"].(name: "Jennifer")
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

      write "app/view.rb", <<~RUBY
        # auto_register: false
        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      write "app/views/users/show.rb", <<~RUBY
        module TestApp
          module Views
            module Users
              class Show < TestApp::View
                expose :name
              end
            end
          end
        end
      RUBY

      write "app/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "app/templates/users/show.html.slim", <<~'SLIM'
        h1 Hello, #{name}
      SLIM

      require "hanami/prepare"

      rendered = TestApp::Application["views.users.show"].(name: "Jennifer")
      expect(rendered.to_s).to eq "<html><body><h1>Hello, Jennifer</h1></body></html>"
    end
  end
end
