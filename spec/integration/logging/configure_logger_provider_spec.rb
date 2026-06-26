# frozen_string_literal: true

RSpec.describe "Logging / Configuring the logger provider", :app_integration do
  specify "a `before :start` hook can customize the same logger that is registered" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.join("log", "test.log")
          end
        end
      RUBY

      write "config/providers/logger.rb", <<~RUBY
        Hanami.app.configure_provider :logger do
          before :start do
            logger.add_backend(
              stream: Hanami.app.root.join("log", "payments.log"),
              log_if: -> entry { entry.tag?(:payments) }
            )
          end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot

      logger = Hanami.app[:logger]

      logger.tagged(:payments) { logger.info("payment received") }
      logger.info("unrelated message")

      payments_log = Hanami.app.root.join("log", "payments.log").read

      expect(payments_log).to include("payment received")
      expect(payments_log).not_to include("unrelated message")
    end
  end
end
