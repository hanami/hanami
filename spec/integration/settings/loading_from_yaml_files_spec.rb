# frozen_string_literal: true

RSpec.describe "Settings / Loading from YAML files", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  def with_app(&block)
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/settings.rb", <<~'RUBY'
        module TestApp
          class Settings < Hanami::Settings
            setting :database_url
            setting :redis_url
          end
        end
      RUBY

      block.call
    end
  end

  specify "settings are loaded from config/settings/default.yml" do
    with_app do
      write "config/settings/default.yml", <<~YAML
        database_url: postgres://localhost/default
        redis_url: redis://localhost/default
      YAML

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/default"
      expect(Hanami.app["settings"].redis_url).to eq "redis://localhost/default"
    end
  end

  specify "settings in the env-specific file take precedence over default.yml" do
    with_app do
      write "config/settings/default.yml", <<~YAML
        database_url: postgres://localhost/default
        redis_url: redis://localhost/default
      YAML

      write "config/settings/development.yml", <<~YAML
        database_url: postgres://localhost/development
      YAML

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/development"
      expect(Hanami.app["settings"].redis_url).to eq "redis://localhost/default"
    end
  end

  specify "settings in ENV take precedence over the YAML files" do
    with_app do
      write "config/settings/default.yml", <<~YAML
        database_url: postgres://localhost/default
        redis_url: redis://localhost/default
      YAML

      write "config/settings/development.yml", <<~YAML
        database_url: postgres://localhost/development
      YAML

      ENV["DATABASE_URL"] = "postgres://localhost/from_env"

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/from_env"
      expect(Hanami.app["settings"].redis_url).to eq "redis://localhost/default"
    end
  end

  specify "slices load settings from the app's YAML files" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/settings/default.yml", <<~YAML
        database_url: postgres://localhost/default
      YAML

      write "slices/main/config/settings.rb", <<~'RUBY'
        module Main
          class Settings < Hanami::Settings
            setting :database_url
          end
        end
      RUBY

      require "hanami/prepare"

      expect(Main::Slice["settings"].database_url).to eq "postgres://localhost/default"
    end
  end

  specify "a store configured in the app class body replaces the default store" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        class TestStore
          def fetch(name, *args, &block)
            {database_url: "from_custom_store"}.fetch(name, *args, &block)
          end
        end

        module TestApp
          class App < Hanami::App
            config.settings_store = TestStore.new
          end
        end
      RUBY

      write "config/settings.rb", <<~'RUBY'
        module TestApp
          class Settings < Hanami::Settings
            setting :database_url
          end
        end
      RUBY

      write "config/settings/default.yml", <<~YAML
        database_url: postgres://localhost/default
      YAML

      ENV["DATABASE_URL"] = "postgres://localhost/from_env"

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "from_custom_store"
    end
  end

  specify "the YAML files are evaluated as ERB" do
    with_app do
      write "config/settings/default.yml", <<~YAML
        database_url: <%= "postgres://localhost/erb" %>
        redis_url: redis://localhost/default
      YAML

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/erb"
    end
  end

  specify "no YAML files are required" do
    with_app do
      ENV["DATABASE_URL"] = "postgres://localhost/from_env"
      ENV["REDIS_URL"] = "redis://localhost/from_env"

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/from_env"
    end
  end
end
