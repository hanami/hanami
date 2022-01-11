RSpec.describe "Container / Standard bootable components", :application_integration do
  specify "Standard components are available on booted container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.boot

      expect(Hanami.application[:settings]).to be_an_instance_of(Hanami::Application::Settings)
      expect(Hanami.application[:inflector]).to eql Hanami.application.inflector
      expect(Hanami.application[:logger]).to be_a_kind_of(Hanami::Logger)
      expect(Hanami.application[:rack_logger]).to be_a_kind_of(Hanami::Web::RackLogger)
    end
  end

  specify "Standard components are resolved lazily on non-booted container" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.init

      expect(Hanami.application[:settings]).to be_an_instance_of(Hanami::Application::Settings)
      expect(Hanami.application[:inflector]).to eql Hanami.application.inflector
      expect(Hanami.application[:logger]).to be_a_kind_of(Hanami::Logger)
      expect(Hanami.application[:rack_logger]).to be_a_kind_of(Hanami::Web::RackLogger)
    end
  end

  specify "Settings component is available when settings are defined" do
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

        module TestApp
          class Settings < Hanami::Application::Settings
            setting :session_secret
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.boot

      expect(Hanami.application[:settings]).to respond_to :session_secret
    end
  end

  specify "Standard components can be replaced by custom bootable components (on booted container)" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/boot/logger.rb", <<~RUBY
        Hanami.application.register_bootable :logger do
          start do
            register :logger, "custom logger"
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.boot

      expect(Hanami.application[:logger]).to eq "custom logger"
    end
  end

  specify "Standard components can be replaced by custom bootable components resolved lazily (on non-booted container)" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "config/boot/logger.rb", <<~RUBY
        Hanami.application.register_bootable :logger do
          start do
            register :logger, "custom logger"
          end
        end
      RUBY

      write "lib/test_app/.keep", ""

      require "hanami/setup"
      Hanami.init

      expect(Hanami.application[:logger]).to eq "custom logger"
    end
  end
end
