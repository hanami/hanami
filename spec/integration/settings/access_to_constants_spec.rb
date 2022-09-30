# frozen_string_literal: true

RSpec.describe "Settings / Access to constants", :app_integration do
  before do
    @env = ENV.to_h
  end

  after do
    ENV.replace(@env)
  end

  describe "Settings can not access autoloadable constants" do
    specify "settings for app" do
      with_directory(make_tmp_directory) do
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
              setting :some_flag, constructor: TestApp::Types::Params::Bool
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

        require "hanami/setup"

        expect { Hanami.app.settings }.to raise_error(NameError, /TestApp::Types/)
      end
    end

    specify "settings for slice" do
      with_directory(make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/config/settings.rb", <<~'RUBY'
          module Main
            class Settings < Hanami::Settings
              setting :some_flag, constructor: Main::Types::Params::Bool
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

        require "hanami/setup"
        Hanami.app.slices.load_slices

        expect { Main::Slice.settings }.to raise_error(NameError, /Main::Types/)
      end
    end
  end
end
