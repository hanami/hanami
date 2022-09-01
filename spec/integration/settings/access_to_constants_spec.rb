# frozen_string_literal: true

RSpec.describe "Settings / Access to constants", :app_integration do
  before do
    @env = ENV.to_h
  end

  after do
    ENV.replace(@env)
  end

  describe "Settings can access autoloadable constants" do
    describe "settings for app" do
      specify "constant defined in app directory" do
        with_directory(make_tmp_directory) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env", <<~'TEXT'
            SOME_FLAG=true
          TEXT

          write "config/settings.rb", <<~'RUBY'
            module TestApp
              class Settings < Hanami::Settings
                setting :some_flag, constructor: Types::Params::Bool
              end
            end
          RUBY

          write "app/types.rb", <<~'RUBY'
            # auto_register: false

            require "dry/types"

            module TestApp
              Types = Dry.Types()
            end
          RUBY

          require "hanami/prepare"

          expect(Hanami.app[:settings].some_flag).to be true
        end
      end

      specify "constant defined in root lib directory" do
        with_directory(make_tmp_directory) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env", <<~'TEXT'
            SOME_FLAG=true
          TEXT

          write "config/settings.rb", <<~'RUBY'
            module TestApp
              class Settings < Hanami::Settings
                setting :some_flag, constructor: Types::Params::Bool
              end
            end
          RUBY

          write "lib/test_app/types.rb", <<~'RUBY'
            require "dry/types"

            module TestApp
              Types = Dry.Types()
            end
          RUBY

          require "hanami/prepare"

          expect(Hanami.app[:settings].some_flag).to be true
        end
      end
    end

    describe "settings for slice" do
      specify "constant defined in slice directory" do
        with_directory(make_tmp_directory) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env", <<~'TEXT'
            SOME_FLAG=true
          TEXT

          write "slices/main/config/settings.rb", <<~'RUBY'
            module Main
              class Settings < Hanami::Settings
                setting :some_flag, constructor: Types::Params::Bool
              end
            end
          RUBY

          write "slices/main/types.rb", <<~'RUBY'
            # auto_register: false

            require "dry/types"

            module Main
              Types = Dry.Types()
            end
          RUBY

          require "hanami/prepare"

          expect(Main::Slice[:settings].some_flag).to be true
        end
      end

      specify "constant defined in root lib directory" do
        with_directory(make_tmp_directory) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env", <<~'TEXT'
            SOME_FLAG=true
          TEXT

          write "slices/main/config/settings.rb", <<~'RUBY'
            module Main
              class Settings < Hanami::Settings
                setting :some_flag, constructor: TestApp::Types::Params::Bool
              end
            end
          RUBY

          write "lib/test_app/types.rb", <<~'RUBY'
            require "dry/types"

            module TestApp
              Types = Dry.Types()
            end
          RUBY

          require "hanami/prepare"

          expect(Main::Slice[:settings].some_flag).to be true
        end
      end
    end
  end
end
