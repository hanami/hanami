# frozen_string_literal: true

RSpec.describe "Settings / Component loading", :app_integration do
  describe "Settings are loaded from a class defined in config/settings.rb" do
    specify "in app" do
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
              setting :foo
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Hanami.app["settings"]).to be_an_instance_of TestApp::Settings
        expect(Hanami.app["settings"]).to respond_to :foo
      end
    end

    specify "in slice" do
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
              setting :foo
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Main::Slice["settings"]).to be_an_instance_of Main::Settings
        expect(Main::Slice["settings"]).to respond_to :foo
      end
    end
  end

  describe "Settings are loaded from a `Settings` class if already defined" do
    specify "in app" do
      with_directory(make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"
          require "hanami/settings"

          module TestApp
            class App < Hanami::App
            end

            class Settings < Hanami::Settings
              setting :foo
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Hanami.app["settings"]).to be_an_instance_of TestApp::Settings
        expect(Hanami.app["settings"]).to respond_to :foo
      end
    end

    specify "in slice" do
      with_directory(make_tmp_directory) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/slices/main.rb", <<~'RUBY'
          require "hanami/settings"

          module Main
            class Slice < Hanami::Slice
            end

            class Settings < Hanami::Settings
              setting :foo
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Main::Slice["settings"]).to be_an_instance_of Main::Settings
        expect(Main::Slice["settings"]).to respond_to :foo
      end
    end
  end
end
