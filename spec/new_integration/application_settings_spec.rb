# frozen_string_literal: true

RSpec.describe "Application settings", :application_integration do
  before do
    @env = ENV.to_h
  end

  after do
    ENV.replace(@env)
  end

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
          setting :feature_flag_with_default, TestApp::Types::Params::Bool.optional.default(false)
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
      expect(Hanami.application.settings.feature_flag_with_default).to be false

      expect(Hanami.application[:settings]).to eql Hanami.application.settings
    end
  end

  specify "Settings with values not matching type expectations will raise an error" do
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
          setting :numeric_setting, TestApp::Types::Params::Integer
          setting :feature_flag, TestApp::Types::Params::Bool
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

      require "hanami/application/settings/loader" # for referencing the error class below

      expect {
        require "hanami/init"
      }.to raise_error(
        Hanami::Application::Settings::Loader::InvalidSettingsError,
        /(numeric_setting:.+invalid value for Integer).+(feature_flag: maybe cannot be coerced)/m
      )
    end
  end

  specify "Settings are available to use when configuring application" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
            config.sessions = :cookie, {secret: settings.session_secret}
          end
        end
      RUBY

      write "config/settings.rb", <<~RUBY
        require "test_app/types"

        Hanami.application.settings do
          setting :session_secret, TestApp::Types::String
        end
      RUBY

      write ".env", <<~RUBY
        SESSION_SECRET=qwerty12345
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
      expect(Hanami.application.config.sessions.options).to eq(secret: "qwerty12345")
    end
  end
end
