# frozen_string_literal: true

require "json"
require "rack/test"
require "stringio"

RSpec.describe "Logging / Request logging", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  let(:logger_stream) { StringIO.new }

  def configure_logger
    Hanami.app.config.logger.stream = logger_stream
  end

  def logs
    @logs ||= (logger_stream.rewind and logger_stream.read)
  end

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

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
end
