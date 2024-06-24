# frozen_string_literal: true

RSpec.describe "DB / Provider / Config", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  # TODO
  specify "default config" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/db/.keep", ""
    end
  end

  it "evaluates plugin config blocks in the context of the provider" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/providers/db.rb", <<~RUBY
        Hanami.app.configure_provider :db do
          config.adapter :sql do |a|
            a.skip_defaults :plugins

            a.plugin relations: :instrumentation do |plugin|
              plugin.notifications = target["custom_notifications"]
            end
          end
        end
      RUBY

      write "app/custom_notifications.rb", <<~RUBY
        module TestApp
          class CustomNotifications
          end
        end
      RUBY

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      Hanami.app.prepare :db

      plugin = Hanami.app["db.config"].setup.plugins.find { _1.name == :instrumentation }
      expect(plugin.config.notifications).to be_an_instance_of TestApp::CustomNotifications
    end
  end

  it "is a Hanami::Providers::DB::Config" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/db/.keep", ""

      ENV["DATABASE_URL"] = "sqlite::memory"

      require "hanami/prepare"

      provider = Hanami.app.container.providers[:db]
      expect(provider.source.config).to be_an_instance_of Hanami::Providers::DB::Config
    end
  end
end
