# frozen_string_literal: true

RSpec.describe "Application view / Collapsed base view file", :application_integration do
  specify "Blah" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/application/view"

        module TestApp
          module View
            class Base < Hanami::Application::View
            end
          end
        end
      RUBY

      write "slices/main/lib/view.rb", <<~RUBY
        # auto_register: false

        module Main
          module View
            class Base < TestApp::View::Base; end
          end
        end
      RUBY

      write "slices/main/views/profile/show.rb", <<~RUBY
        module Main
          module Views
            module Profile
              class Show < Main::View::Base
                expose :name
              end
            end
          end
        end
      RUBY

      write "slices/main/templates/layouts/application.html.slim", <<~SLIM
        == yield
      SLIM

      write "slices/main/templates/profile/show.html.slim", <<~'SLIM'
        p Hello #{name}
      SLIM

      require "hanami/prepare"

      view = Main::Slice["views.profile.show"]
      output = view.call(name: "Jenny").to_s

      expect(output).to eq <<~HTML.strip
        <p>Hello Jenny</p>
      HTML
    end
  end
end
