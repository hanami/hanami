# frozen_string_literal: true

RSpec.describe "Settings / Access to constants", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "settings are loaded from ENV" do
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
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "postgres://localhost/database"

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/database"
    end
  end

  describe "settings are loaded from .env files" do
    context "hanami env is development" do
      it "loads settings from .env.development.local, .env.local, .env.development and .env (in this order)" do
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
                setting :from_specific_env_local
                setting :from_base_local
                setting :from_specific_env
                setting :from_base
              end
            end
          RUBY

          write ".env.development.local", <<~'TEXT'
            FROM_SPECIFIC_ENV_LOCAL="from .env.development.local"
          TEXT

          write ".env.local", <<~'TEXT'
            FROM_BASE_LOCAL="from .env.local"

            FROM_SPECIFIC_ENV_LOCAL=nope
          TEXT

          write ".env.development", <<~'TEXT'
            FROM_SPECIFIC_ENV="from .env.development"

            FROM_SPECIFIC_ENV_LOCAL=nope
            FROM_BASE_LOCAL=nope
          TEXT

          write ".env", <<~'TEXT'
            FROM_BASE="from .env"

            FROM_SPECIFIC_ENV_LOCAL=nope
            FROM_BASE_LOCAL=nope
            FROM_SPECIFIC_ENV=nope
          TEXT

          ENV["HANAMI_ENV"] = "development"

          require "hanami/prepare"

          expect(Hanami.app["settings"].from_specific_env_local).to eq "from .env.development.local"
          expect(Hanami.app["settings"].from_base_local).to eq "from .env.local"
          expect(Hanami.app["settings"].from_specific_env).to eq "from .env.development"
          expect(Hanami.app["settings"].from_base).to eq "from .env"
        end
      end

      context "hanami env is test" do
        it "loads settings from .env.development.local, .env.development and .env (in this order)" do
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
                  setting :from_specific_env_local
                  setting :from_base_local
                  setting :from_specific_env
                  setting :from_base
                end
              end
            RUBY

            write ".env.test.local", <<~'TEXT'
              FROM_SPECIFIC_ENV_LOCAL="from .env.test.local"
            TEXT

            write ".env.local", <<~'TEXT'
              FROM_BASE_LOCAL="from .env.local"
            TEXT

            write ".env.test", <<~'TEXT'
              FROM_SPECIFIC_ENV="from .env.test"

              FROM_SPECIFIC_ENV_LOCAL=nope
            TEXT

            write ".env", <<~'TEXT'
              FROM_BASE="from .env"

              FROM_SPECIFIC_ENV_LOCAL=nope
              FROM_SPECIFIC_ENV=nope
            TEXT

            ENV["HANAMI_ENV"] = "test"

            require "hanami/prepare"

            expect(Hanami.app["settings"].from_specific_env_local).to eq "from .env.test.local"
            expect(Hanami.app["settings"].from_base_local).to be nil
            expect(Hanami.app["settings"].from_specific_env).to eq "from .env.test"
            expect(Hanami.app["settings"].from_base).to eq "from .env"
          end
        end
      end
    end
  end

  it "prefers ENV values are preferred over .env files" do
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
          end
        end
      RUBY

      write ".env", <<~'TEXT'
        DATABASE_URL=nope
      TEXT

      ENV["DATABASE_URL"] = "postgres://localhost/database"

      require "hanami/prepare"

      expect(Hanami.app["settings"].database_url).to eq "postgres://localhost/database"
    end
  end
end
