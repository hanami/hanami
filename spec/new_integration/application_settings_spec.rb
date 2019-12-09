# frozen_string_literal: true

RSpec.describe "Application settings", :application_integration do
  specify "Settings defined in config/settings.rb are loaded from .env and run through optional callable (type) objects" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        require "test_app/types"

        Hanami.application.settings do
          setting :database_url
          setting :redis_url
          setting :feature_flag, TestApp::Types::Params::Bool
        end
      RUBY

      write ".env", <<~RUBY
        DATABASE_URL=postgres://localhost/test_app_development
        REDIS_URL=redis://localhost:6379
        FEATURE_FLAG=true
      RUBY

      write "lib/test_app/types.rb", <<~RUBY
        require "dry/types"

        module TestApp
          module Types
            include Dry.Types()
          end
        end
      RUBY

      require "hanami/init"

      expect(Hanami.application.settings.database_url).to eq "postgres://localhost/test_app_development"
      expect(Hanami.application.settings.redis_url).to eq "redis://localhost:6379"
      expect(Hanami.application.settings.feature_flag).to be true

      expect(Hanami.application[:settings]).to eql Hanami.application.settings
    end
  end
end
