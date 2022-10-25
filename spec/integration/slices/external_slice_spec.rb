# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Slices / External slices", :app_integration do
  include Rack::Test::Methods

  let(:app) { TestApp::App.app }

  specify "External slices can be registered and used" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new

            require "external/slice"
            register_slice(:external, External::Slice)
          end
        end
      RUBY

      write "config/routes.rb", <<~'RUBY'
        require "hanami/routes"

        module TestApp
          class Routes < Hanami::Routes
            slice :external, at: "/" do
              root to: "test_action"
            end
          end
        end
      RUBY

      # Put a slice and its components in `lib/external/`, as if it were an external gem

      write "lib/external/slice.rb", <<~'RUBY'
        # auto_register: false

        require "hanami/slice"

        module External
          class Slice < Hanami::Slice
            config.root = __dir__
          end
        end
      RUBY

      # FIXME: Remove redundant `lib/` dir once hanami/hanami#1174 is merged
      write "lib/external/lib/test_repo.rb", <<~'RUBY'
        require "hanami/slice"

        module External
          class TestRepo
            def things
              %w[foo bar baz]
            end
          end
        end
      RUBY

      write "lib/external/actions/test_action.rb", <<~'RUBY'
        require "hanami/action"

        module External
          module Actions
            class TestAction < Hanami::Action
              include Deps["test_repo"]

              def handle(req, res)
                res.body = test_repo.things.join(", ")
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Hanami.app.slices[:external]).to be External::Slice

      get "/"

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq "foo, bar, baz"
    end
  end
end
