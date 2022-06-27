# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Context / Routes", :application_integration do
  xit "accesses application routes" do
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
          class Routes < Hanami::Routes
            define do
              root to: "test_action"
            end
          end
        end
      RUBY

      write "app/views/context.rb", <<~RUBY
        require "hanami/view/context"

        module TestApp
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      RUBY

      require "hanami/prepare"

      context = TestApp::Views::Context.new
      expect(context.routes.path(:root)).to eq "/"
    end
  end

  it "can inject routes" do
    module TestApp
      class Application < Hanami::Application
      end
    end

    Hanami.prepare

    module TestApp
      module Views
        class Context < Hanami::View::Context
        end
      end
    end

    routes = double(:routes)

    context = TestApp::Views::Context.new(routes: routes)

    expect(context.routes).to be(routes)
  end
end
