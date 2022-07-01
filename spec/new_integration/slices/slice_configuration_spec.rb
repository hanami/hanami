# frozen_string_literal: true

RSpec.describe "Slices / Slice configuration", :application_integration do
  specify "Slices receive a copy of the application configuration, and can make distinct modifications" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.logger.stream = File.new("/dev/null", "w")

            config.no_auto_register_paths << "structs"
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

      expect(TestApp::Application.config.no_auto_register_paths).to eq %w[entities structs]
      expect(Main::Slice.config.no_auto_register_paths).to eq %w[entities structs schemas]
      expect(Search::Slice.config.no_auto_register_paths).to eq %w[entities structs]
    end
  end
end
