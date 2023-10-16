# frozen_string_literal: true

require "json"
require "rack/test"
require "stringio"

RSpec.describe "Logging / Request logging", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  let(:logger_stream) { StringIO.new }

  let(:root) { make_tmp_directory }

  def configure_logger
    Hanami.app.config.logger.stream = logger_stream
  end

  def logs
    @logs ||= (logger_stream.rewind and logger_stream.read)
  end

  def generate_app
    write "config/app.rb", <<~RUBY
    module TestApp
      class App < Hanami::App
      end
    end
    RUBY
  end

  before do
    with_directory(root) do
      generate_app

      require "hanami/setup"
      configure_logger

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app router" do
    def before_prepare
      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: ->(env) { [200, {}, ["OK"]] }
          end
        end
      RUBY
    end

    it "logs the requests" do
      get "/"

      expect(logs.split("\n").length).to eq 1
      expect(logs).to match %r{GET 200 \d+(µs|ms) 127.0.0.1 /}
    end

    context "production env" do
      around do |example|
        @prev_hanami_env = ENV["HANAMI_ENV"]
        ENV["HANAMI_ENV"] = "production"
        example.run
      ensure
        ENV["HANAMI_ENV"] = @prev_hanami_env
      end

      it "logs the requests as JSON" do
        get "/"

        expect(logs.split("\n").length).to eq 1

        json = JSON.parse(logs, symbolize_names: true)
        expect(json).to include(
          verb: "GET",
          path: "/",
          ip: "127.0.0.1",
          elapsed: Integer,
          elapsed_unit: a_string_matching(/(µs|ms)/),
        )
      end
    end
  end

  describe "slice router" do
    let(:app) { Main::Slice.rack_app }

    def before_prepare
      write "slices/main/config/routes.rb", <<~RUBY
        module Main
          class Routes < Hanami::Routes
            root to: ->(env) { [200, {}, ["OK"]] }
          end
        end
      RUBY
    end

    it "logs the requests" do
      get "/"

      expect(logs.split("\n").length).to eq 1
      expect(logs).to match %r{GET 200 \d+(µs|ms) 127.0.0.1 /}
    end

    context "production env" do
      around do |example|
        @prev_hanami_env = ENV["HANAMI_ENV"]
        ENV["HANAMI_ENV"] = "production"
        example.run
      ensure
        ENV["HANAMI_ENV"] = @prev_hanami_env
      end

      it "logs the requests as JSON" do
        get "/"

        expect(logs.split("\n").length).to eq 1

        json = JSON.parse(logs, symbolize_names: true)
        expect(json).to include(
          verb: "GET",
          path: "/",
          ip: "127.0.0.1",
          elapsed: Integer,
          elapsed_unit: a_string_matching(/(µs|ms)/),
        )
      end
    end
  end

  context "when using ::Logger from Ruby stdlib" do
    def generate_app
      write "config/app.rb", <<~RUBY
        require "logger"
        require "pathname"

        module TestApp
          class App < Hanami::App
            stream = Pathname.new(#{root.to_s.inspect}).join("log").tap(&:mkpath).join("test.log").to_s
            config.logger = ::Logger.new(stream, progname: "custom-logger-app")
          end
        end
      RUBY
    end

    def before_prepare
      with_directory(root) do
        write "config/routes.rb", <<~RUBY
          module TestApp
            class Routes < Hanami::Routes
              root to: ->(env) { [200, {}, ["OK"]] }
            end
          end
        RUBY
      end
    end

    let(:logs) do
      Pathname.new(root).join("log", "test.log").readlines
    end

    it "logs the requests with the payload serialized as JSON" do
      get "/"

      request_log = logs.last

      # Expected log line follows the standard Logger structure:
      #
      # I, [2023-10-14T14:55:16.638753 #94836]  INFO -- custom-logger-app: {"verb":"GET", ...}
      expect(request_log).to match(%r{INFO -- custom-logger-app:})

      # The log message should be JSON, after the progname
      log_message = request_log.split("custom-logger-app: ").last
      log_payload = JSON.parse(log_message, symbolize_names: true)

      expect(log_payload).to include(
        verb: "GET",
        status: 200
      )
    end
  end
end
