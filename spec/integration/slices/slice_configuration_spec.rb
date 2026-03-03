# frozen_string_literal: true

require "stringio"

RSpec.describe "Slices / Slice configuration", :app_integration do
  specify "Slices receive a copy of the app configuration, and can make distinct modifications" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new

            config.no_auto_register_paths = ["structs"]
          end
        end
      RUBY

      write "config/slices/main.rb", <<~'RUBY'
        module Main
          class Slice < Hanami::Slice
            config.no_auto_register_paths << "schemas"
          end
        end
      RUBY

      write "config/slices/search.rb", <<~'RUBY'
        module Search
          class Slice < Hanami::Slice
          end
        end
      RUBY

      require "hanami/prepare"

      expect(TestApp::App.config.no_auto_register_paths).to eq %w[structs]
      expect(Main::Slice.config.no_auto_register_paths).to eq %w[structs schemas]
      expect(Search::Slice.config.no_auto_register_paths).to eq %w[structs]
    end
  end

  specify "Slices can configure memoization for specific component namespaces" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.memoize_component_namespaces = ["actions.", "views."]
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
            # Inherits from app
          end
        end
      RUBY

      write "config/slices/search.rb", <<~RUBY
        module Search
          class Slice < Hanami::Slice
            config.memoize_component_namespaces = []
          end
        end
      RUBY

      require "hanami/prepare"

      expect(TestApp::App.config.memoize_component_namespaces).to eq ["actions.", "views."]
      expect(Main::Slice.config.memoize_component_namespaces).to eq ["actions.", "views."]
      expect(Search::Slice.config.memoize_component_namespaces).to eq []
    end
  end

  specify "Components in memoized namespaces return the same instance" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.memoize_component_namespaces = ["actions."]
          end
        end
      RUBY

      write "slices/main/actions/show.rb", <<~RUBY
        module Main
          module Actions
            class Show
            end
          end
        end
      RUBY

      write "slices/main/repos/user_repo.rb", <<~RUBY
        module Main
          module Repos
            class UserRepo
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Main::Slice["actions.show"]).to be(Main::Slice["actions.show"])
      expect(Main::Slice["repos.user_repo"]).not_to be(Main::Slice["repos.user_repo"])
    end
  end

  specify "Memoization only matches exact namespace boundaries" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.memoize_component_namespaces = ["actions."]
          end
        end
      RUBY

      write "slices/main/actions/show.rb", <<~RUBY
        module Main
          module Actions
            class Show
            end
          end
        end
      RUBY

      write "slices/main/actions_legacy/cleanup.rb", <<~RUBY
        module Main
          module ActionsLegacy
            class Cleanup
            end
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Main::Slice["actions.show"]).to be(Main::Slice["actions.show"])
      expect(Main::Slice["actions_legacy.cleanup"]).not_to be(Main::Slice["actions_legacy.cleanup"])
    end
  end

  describe "memoize_component_namespaces validation" do
    specify "requires an Array" do
      expect {
        Hanami::Config.new(app_name: :test_app, env: :test).memoize_component_namespaces = "actions."
      }.to raise_error(ArgumentError, /must be an Array/)
    end

    specify "requires trailing dots" do
      expect {
        Hanami::Config.new(app_name: :test_app, env: :test).memoize_component_namespaces = ["actions"]
      }.to raise_error(ArgumentError, /must end with a dot/)
    end
  end
end
