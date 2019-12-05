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
        end
      RUBY

      write ".env", <<~RUBY
        DATABASE_URL=postgres://localhost/test_app_development
      RUBY

      require "hanami/init"

      expect(Hanami.application.settings.database_url).to eq "postgres://localhost/test_app_development"
    end
  end
end
