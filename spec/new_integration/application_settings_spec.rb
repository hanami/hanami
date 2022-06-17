# frozen_string_literal: true

require "hanami/application/settings"

RSpec.describe "Application settings", :application_integration do
  before do
    @env = ENV.to_h
  end

  after do
    ENV.replace(@env)
  end

  specify "Settings defined in config/settings.rb are loaded from .env" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        require "hanami/application/settings"
        require "test_app/types"

        module TestApp
          class Settings < Hanami::Application::Settings
            setting :database_url
            setting :redis_url
            setting :feature_flag, constructor: TestApp::Types::Params::Bool
            setting :feature_flag_with_default, default: false, constructor: TestApp::Types::Params::Bool
          end
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

      require "hanami/prepare"

      expect(Hanami.application.settings.database_url).to eq "postgres://localhost/test_app_development"
      expect(Hanami.application.settings.redis_url).to eq "redis://localhost:6379"
      expect(Hanami.application.settings.feature_flag).to be true
      expect(Hanami.application.settings.feature_flag_with_default).to be false

      expect(Hanami.application[:settings]).to eql Hanami.application.settings
    end
  end

  specify "Errors raised from setting constructors are collected" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        require "hanami/application/settings"
        require "test_app/types"

        module TestApp
          class Settings < Hanami::Application::Settings
            setting :numeric_setting, constructor: TestApp::Types::Params::Integer
            setting :feature_flag, constructor: TestApp::Types::Params::Bool
          end
        end
      RUBY

      write ".env", <<~RUBY
        NUMERIC_SETTING=hello
        FEATURE_FLAG=maybe
      RUBY

      write "lib/test_app/types.rb", <<~RUBY
        require "dry/types"

        module TestApp
          module Types
            include Dry.Types()
          end
        end
      RUBY

      numeric_setting_error = "numeric_setting: invalid value for Integer"
      feature_flag_error = "feature_flag: maybe cannot be coerced"

      expect {
        require "hanami/prepare"
      }.to raise_error(
        Hanami::Application::Settings::InvalidSettingsError,
        /#{numeric_setting_error}.+#{feature_flag_error}|#{feature_flag_error}.+#{numeric_setting_error}/m
      )
    end
  end
end
