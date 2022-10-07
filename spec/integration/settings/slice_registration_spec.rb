# frozen_string_literal: true

RSpec.describe "Settings / Slice registration", :app_integration do
  specify "Settings are registered for each slice with a settings file" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      # n.b. no app-level settings file

      # The main slice has settings
      write "slices/main/config/settings.rb", <<~RUBY
        # frozen_string_literal: true

        require "hanami/settings"

        module Main
          class Settings < Hanami::Settings
            setting :main_session_secret
          end
        end
      RUBY

      # The admin slice has none
      write "slices/admin/.keep", ""

      require "hanami/prepare"

      expect(Main::Slice.key?("settings")).to be true
      expect(Main::Slice["settings"]).to respond_to :main_session_secret

      expect(Admin::Slice.key?("settings")).to be false
    end
  end

  describe "App settings are shared with slices if no local settings are defined" do
    context "prepared" do
      specify do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~RUBY
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "config/settings.rb", <<~'RUBY'
            # frozen_string_literal: true

            require "hanami/settings"

            module TestApp
              class Settings < Hanami::Settings
                setting :app_session_secret
              end
            end
          RUBY

          write "slices/main/config/settings.rb", <<~RUBY
            # frozen_string_literal: true

            require "hanami/settings"

            module Main
              class Settings < Hanami::Settings
                setting :main_session_secret
              end
            end
          RUBY

          write "slices/admin/.keep", ""

          require "hanami/prepare"

          expect(TestApp::App.key?("settings")).to be true
          expect(Main::Slice.key?("settings")).to be true
          expect(Admin::Slice.key?("settings")).to be true

          expect(TestApp::App["settings"]).to respond_to :app_session_secret
          expect(Main::Slice["settings"]).to respond_to :main_session_secret
          expect(Admin::Slice["settings"]).to respond_to :app_session_secret
        end
      end
    end

    context "booted" do
      specify do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~RUBY
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "config/settings.rb", <<~'RUBY'
            # frozen_string_literal: true

            require "hanami/settings"

            module TestApp
              class Settings < Hanami::Settings
                setting :app_session_secret
              end
            end
          RUBY

          write "slices/main/config/settings.rb", <<~RUBY
            # frozen_string_literal: true

            require "hanami/settings"

            module Main
              class Settings < Hanami::Settings
                setting :main_session_secret
              end
            end
          RUBY

          write "slices/admin/.keep", ""

          require "hanami/boot"

          expect(TestApp::App.key?("settings")).to be true
          expect(Main::Slice.key?("settings")).to be true
          expect(Admin::Slice.key?("settings")).to be true

          expect(TestApp::App["settings"]).to respond_to :app_session_secret
          expect(Main::Slice["settings"]).to respond_to :main_session_secret
          expect(Admin::Slice["settings"]).to respond_to :app_session_secret
        end
      end
    end
  end
end
