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

      expect(TestApp::App.config.no_auto_register_paths).to eq %w[entities structs]
      expect(Main::Slice.config.no_auto_register_paths).to eq %w[entities structs schemas]
      expect(Search::Slice.config.no_auto_register_paths).to eq %w[entities structs]
    end
  end
end
