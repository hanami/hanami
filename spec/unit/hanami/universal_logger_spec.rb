# frozen_string_literal: true

RSpec.describe Hanami::UniversalLogger do
  # Shared logger test doubles
  let(:structured_logger) do
    Class.new do
      attr_reader :logs

      def initialize
        @logs = []
      end

      %i[debug info warn error fatal unknown].each do |level|
        define_method(level) do |message = nil, **payload|
          @logs << {level: level, message: message, payload: payload}
        end
      end
    end.new
  end

  let(:legacy_logger) do
    Class.new do
      attr_reader :logs

      def initialize
        @logs = []
      end

      %i[debug info warn error fatal unknown].each do |level|
        define_method(level) do |message|
          @logs << {level: level, message: message}
        end
      end
    end.new
  end

  # Shared examples for common behaviors
  shared_examples "logging method" do |level, structured:|
    it "logs with message and payload" do
      wrapped.public_send(level, "Test message", key: "value")

      log = logger.logs.last
      expect(log[:level]).to eq(level)

      if structured
        expect(log[:message]).to eq("Test message")
        expect(log[:payload]).to eq(key: "value")
      else
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed).to eq(message: "Test message", key: "value")
      end
    end

    it "supports block form" do
      wrapped.public_send(level) { {data: 123} }

      log = logger.logs.last
      expect(log[:level]).to eq(level)

      if structured
        expect(log[:payload]).to eq(data: 123)
      else
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed).to eq(data: 123)
      end
    end
  end

  shared_examples "tagged logging" do |structured:|
    it "includes tags in the payload" do
      wrapped.tagged(:request) do
        wrapped.info("Message", user_id: 123)
      end

      log = logger.logs.last

      if structured
        expect(log[:payload][:tags]).to eq([:request])
      else
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed[:tags]).to eq(["request"])
      end
    end

    it "supports multiple tags" do
      wrapped.tagged(:request, :api) do
        wrapped.info("Message")
      end

      log = logger.logs.last

      if structured
        expect(log[:payload][:tags]).to eq([:request, :api])
      else
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed[:tags]).to eq(["request", "api"])
      end
    end

    it "clears tags after block completes" do
      wrapped.tagged(:temporary) do
        wrapped.info("Tagged")
      end
      wrapped.info("Untagged")

      if structured
        expect(logger.logs[0][:payload][:tags]).to eq([:temporary])
        expect(logger.logs[1][:payload][:tags]).to be_nil
      else
        parsed1 = JSON.parse(logger.logs[0][:message], symbolize_names: true)
        parsed2 = JSON.parse(logger.logs[1][:message], symbolize_names: true)
        expect(parsed1[:tags]).to eq(["temporary"])
        expect(parsed2[:tags]).to be_nil
      end
    end

    it "handles nested tagging" do
      wrapped.tagged(:outer) do
        wrapped.info("Outer")
        wrapped.tagged(:inner) do
          wrapped.info("Inner")
        end
        wrapped.info("Back to outer")
      end

      if structured
        expect(logger.logs[0][:payload][:tags]).to eq([:outer])
        expect(logger.logs[1][:payload][:tags]).to eq([:inner])
        expect(logger.logs[2][:payload][:tags]).to eq([:outer])
      else
        parsed = logger.logs.map { |l| JSON.parse(l[:message], symbolize_names: true) }
        expect(parsed[0][:tags]).to eq(["outer"])
        expect(parsed[1][:tags]).to eq(["inner"])
        expect(parsed[2][:tags]).to eq(["outer"])
      end
    end

    it "returns the block result" do
      result = wrapped.tagged(:test) { "return value" }
      expect(result).to eq("return value")
    end

    it "ensures tags are cleared on exception" do
      expect {
        wrapped.tagged(:error_tag) { raise "Test error" }
      }.to raise_error("Test error")

      wrapped.info("After error")

      log = logger.logs.last
      if structured
        expect(log[:payload][:tags]).to be_nil
      else
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed[:tags]).to be_nil
      end
    end

    it "maintains thread-safe tag isolation" do
      # Create a second independent logger instance
      logger_2 = logger.class.new
      wrapped_2 = described_class[logger_2]

      threads = []
      threads << Thread.new do
        wrapped.tagged(:logger_1) do
          sleep(0.001)
          wrapped.info("Message 1")
        end
      end

      threads << Thread.new do
        wrapped_2.tagged(:logger_2) do
          sleep(0.001)
          wrapped_2.info("Message 2")
        end
      end

      threads.each(&:join)

      if structured
        expect(logger.logs.first[:payload][:tags]).to eq([:logger_1])
        expect(logger_2.logs.first[:payload][:tags]).to eq([:logger_2])
      else
        parsed1 = JSON.parse(logger.logs.first[:message], symbolize_names: true)
        parsed2 = JSON.parse(logger_2.logs.first[:message], symbolize_names: true)
        expect(parsed1[:tags]).to eq(["logger_1"])
        expect(parsed2[:tags]).to eq(["logger_2"])
      end
    end
  end

  describe ".call" do
    it "returns logger unchanged if it has keyword args and #tagged" do
      logger = Class.new do
        def tagged(*tags); end
        def info(message = nil, **payload); end
      end.new

      result = described_class.call(logger)
      expect(result).to be(logger)
    end

    it "wraps logger if it has keyword args but no #tagged" do
      logger = Class.new do
        def info(message = nil, **payload); end
      end.new

      result = described_class.call(logger)
      expect(result).to be_a(described_class)
      expect(result.logger).to be(logger)
    end

    it "wraps logger if it only accepts positional args" do
      logger = Class.new do
        def info(message); end
      end.new

      result = described_class.call(logger)
      expect(result).to be_a(described_class)
      expect(result.logger).to be(logger)
    end
  end

  describe "with structured-capable logger" do
    let(:logger) { structured_logger }
    let(:wrapped) { described_class[logger] }

    describe "#info" do
      include_examples "logging method", :info, structured: true
    end

    describe "#error" do
      include_examples "logging method", :error, structured: true
    end

    describe "#tagged" do
      include_examples "tagged logging", structured: true
    end

    describe "#add" do
      it "converts severity integers to log levels" do
        wrapped.add(1, "Info message")
        expect(logger.logs.last[:level]).to eq(:info)
        expect(logger.logs.last[:message]).to eq("Info message")
      end

      it "includes progname in payload" do
        wrapped.add(1, "Test", "MyApp")
        expect(logger.logs.last[:payload][:progname]).to eq("MyApp")
      end

      it "works with tags" do
        wrapped.tagged(:request) do
          wrapped.add(1, "Tagged", "MyApp")
        end
        expect(logger.logs.last[:payload][:tags]).to eq([:request])
      end

      it "supports block form" do
        wrapped.add(1) { {action: "test"} }
        expect(logger.logs.last[:payload]).to eq(action: "test")
      end

      it "handles different severity levels" do
        wrapped.add(0, "Debug")
        wrapped.add(2, "Warning")
        wrapped.add(3, "Error")

        expect(logger.logs[0][:level]).to eq(:debug)
        expect(logger.logs[1][:level]).to eq(:warn)
        expect(logger.logs[2][:level]).to eq(:error)
      end
    end
  end

  describe "with legacy logger" do
    let(:logger) { legacy_logger }
    let(:wrapped) { described_class[logger] }

    describe "#info" do
      include_examples "logging method", :info, structured: false

      it "handles payload without message" do
        wrapped.info(user_id: 123, action: "login")

        log = logger.logs.last
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed).to eq(user_id: 123, action: "login")
      end
    end

    describe "#error" do
      include_examples "logging method", :error, structured: false
    end

    describe "#tagged" do
      include_examples "tagged logging", structured: false
    end

    describe "#add" do
      it "serializes to JSON with progname" do
        wrapped.add(1, "Info message", "MyApp")

        log = logger.logs.last
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed).to eq(message: "Info message", progname: "MyApp")
      end

      it "includes tags in JSON output" do
        wrapped.tagged(:request) do
          wrapped.add(3, "Error", "MyApp")
        end

        log = logger.logs.last
        parsed = JSON.parse(log[:message], symbolize_names: true)
        expect(parsed).to eq(message: "Error", progname: "MyApp", tags: ["request"])
      end
    end
  end

  describe "missing method delegation" do
    let(:logger) do
      Class.new do
        attr_reader :custom_attribute

        def initialize
          @custom_attribute = "custom value"
        end

        def info(message = nil, **payload); end
        def custom_method(arg); "result: #{arg}"; end # rubocop:disable Style/SingleLineMethods
      end.new
    end

    let(:wrapped) { described_class[logger] }

    it "delegates to wrapped logger" do
      expect(wrapped.custom_method("test")).to eq("result: test")
      expect(wrapped.custom_attribute).to eq("custom value")
    end

    it "raises NoMethodError for non-existent methods" do
      expect { wrapped.nonexistent }.to raise_error(NoMethodError)
    end
  end
end
