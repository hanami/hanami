# frozen_string_literal: true

RSpec.describe "Application routes helper", :application_integration do
  specify "Routes helper is registered in the container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Application::Routes
            define do
              slice :main, at: "/" do
                root to: "home#index"
              end
            end
          end
        end
      RUBY

      write "slices/main/lib/main/actions/home/index.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            module Home
              class Index < Hanami::Action
                def handle(*, res)
                  res.body = "Hello world"
                end
              end
            end
          end
        end
      RUBY

      require "hanami/init"

      expect(TestApp::Application["routes_helper"].path(:root)).to eq "/"
    end
  end
end
