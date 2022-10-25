# frozen_string_literal: true

require "stringio"

RSpec.describe "App routes helper", :app_integration do
  specify "Routing to actions based on their container identifiers" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: "home.index"
          end
        end
      RUBY

      write "app/actions/home/index.rb", <<~RUBY
        require "hanami/action"

        module TestApp
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

      require "hanami/prepare"

      expect(TestApp::App["routes"].path(:root)).to eq "/"
      expect(TestApp::App["routes"].url(:root).to_s).to match /http:\/\/.*\//
    end
  end
end
