# frozen_string_literal: true

RSpec.describe "Slices / Slice-registered providers", :app_integration do
  specify "a logger provider registered on a slice builds the logger from the slice's own config" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "slices/admin/config/slice.rb", <<~'RUBY'
        require "stringio"

        module Admin
          class Slice < Hanami::Slice
            # Provide our own logger rather than importing the app's
            config.shared_app_component_keys -= ["logger"]
            config.logger.stream = StringIO.new
          end
        end
      RUBY

      write "slices/admin/config/providers/logger.rb", <<~'RUBY'
        require "hanami/providers/logger"

        Admin::Slice.configure_provider(:logger)
      RUBY

      require "hanami/prepare"

      Admin::Slice["logger"].info("hello from admin")

      expect(Admin::Slice.config.logger.stream.string).to include "hello from admin"
    end
  end

  specify "an inflector provider registered on a slice registers the slice's own inflector" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      write "slices/admin/config/slice.rb", <<~'RUBY'
        module Admin
          class Slice < Hanami::Slice
            # Provide our own inflector rather than importing the app's
            config.shared_app_component_keys -= ["inflector"]

            # Configuring inflections gives the slice an inflector instance of its own
            config.inflections do |inflections|
              inflections.acronym "API"
            end
          end
        end
      RUBY

      write "slices/admin/config/providers/inflector.rb", <<~'RUBY'
        require "hanami/providers/inflector"

        Admin::Slice.register_provider(:inflector, source: Hanami::Providers::Inflector)
      RUBY

      require "hanami/prepare"

      expect(Admin::Slice["inflector"]).to be Admin::Slice.inflector
      expect(Admin::Slice["inflector"]).not_to be TestApp::App.inflector
    end
  end
end
