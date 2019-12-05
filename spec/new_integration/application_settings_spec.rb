# frozen_string_literal: true

RSpec.describe "Application settings", :application_integration do
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
        Hanami.application.settings do
          setting :database_url
          setting :redis_url
        end
      RUBY

      write ".env", <<~RUBY
        DATABASE_URL=postgres://localhost/test_app_development
        REDIS_URL=redis://localhost:6379
      RUBY

      require "hanami/init"

      expect(Hanami.application.settings.database_url).to eq "postgres://localhost/test_app_development"
      expect(Hanami.application.settings.redis_url).to eq "redis://localhost:6379"
    end
  end
end
