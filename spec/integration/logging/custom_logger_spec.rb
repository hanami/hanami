# frozen_string_literal: true

require "rack/test"
require "stringio"
require "logger"
require "dry/logger"

RSpec.describe "Logging / Custom logger integration", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }
  let(:root) { make_tmp_directory }

  before do
    stub_const("TEST_LOGGER", logger_instance)

    with_directory(root) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger = TEST_LOGGER
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: ->(env) { [200, {}, ["OK"]] }
          end
        end
      RUBY

      require "hanami/setup"
      require "hanami/prepare"
    end
  end

  context "with a fully compatible logger (Dry::Logger)" do
    let(:io) { StringIO.new }

    # Custom formatter that includes tags in the output
    let(:formatter_class) do
      Class.new(Dry::Logger::Formatters::JSON) do
        def format_values(entry)
          hash = super
          hash[:tags] = entry.tags unless entry.tags.empty?
          hash
        end
      end
    end

    let(:logger_instance) do
      Dry.Logger(:test, stream: io, formatter: formatter_class.new)
    end

    it "passes through unchanged - no wrapping by UniversalLogger" do
      get "/"

      io.rewind
      output = io.read

      parsed = JSON.parse(output, symbolize_names: true)
      expect(parsed[:verb]).to eq("GET")
      expect(parsed[:status]).to eq(200)
      expect(parsed[:path]).to eq("/")
      expect(parsed[:tags]).to eq(["rack"])

      # Dry Logger was not wrapped by UniversalLogger
      expect(Hanami.app["logger"]).to be_a(Dry::Logger::Dispatcher)
    end

    it "supports direct logging with tagged blocks" do
      logger = Hanami.app["logger"]

      logger.tagged(:custom_tag) do
        logger.info("User action", user_id: 456)
      end

      io.rewind
      output = io.read

      parsed = JSON.parse(output, symbolize_names: true)
      expect(parsed[:message]).to eq("User action")
      expect(parsed[:user_id]).to eq(456)
      expect(parsed[:tags]).to eq(["custom_tag"])
    end
  end

  context "with a structured-capable logger (keyword args but no tagged method)" do
    let(:logger_class) do
      Class.new do
        attr_reader :logs

        def initialize
          @logs = []
        end

        %i[debug info warn error fatal unknown].each do |level|
          define_method(level) do |message = nil, **payload, &block|
            entry = {level: level, message: message, payload: payload}
            entry[:result] = block.call if block
            @logs << entry
          end
        end
      end
    end

    let(:logger_instance) { logger_class.new }

    it "logs HTTP requests with tags in the payload" do
      get "/"

      logger = Hanami.app["logger"]
      log_entry = logger.logs.first

      expect(log_entry[:level]).to eq(:info)
      expect(log_entry[:payload]).to include(verb: "GET", status: 200, path: "/")
      expect(log_entry[:payload][:tags]).to eq([:rack])
    end

    it "supports direct logging with tagged blocks" do
      logger = Hanami.app["logger"]

      logger.tagged(:custom_tag) do
        logger.info("User login", user_id: 123)
      end

      log_entry = logger.logs.last
      expect(log_entry[:payload]).to include(user_id: 123)
      expect(log_entry[:payload][:tags]).to eq([:custom_tag])
    end
  end

  context "with a legacy logger (stdlib Logger)" do
    let(:io) { StringIO.new }
    let(:logger_instance) { Logger.new(io) }

    it "receives JSON-serialized data with tags" do
      get "/"

      io.rewind
      output = io.read

      # Extract the JSON from the log line (after the log level and timestamp)
      json_match = output.match(/INFO -- : (.+)$/)
      expect(json_match).not_to be_nil

      parsed = JSON.parse(json_match[1], symbolize_names: true)
      expect(parsed).to include(verb: "GET", status: 200, path: "/")
      expect(parsed[:tags]).to eq(["rack"])
    end

    it "serializes direct logging with tagged blocks to JSON" do
      logger = Hanami.app["logger"]

      logger.tagged(:custom_tag) do
        logger.info("User action", user_id: 456)
      end

      io.rewind
      output = io.read

      json_match = output.match(/INFO -- : (.+)$/)
      parsed = JSON.parse(json_match[1], symbolize_names: true)
      expect(parsed).to include(user_id: 456)
      expect(parsed[:tags]).to eq(["custom_tag"])
    end
  end
end
