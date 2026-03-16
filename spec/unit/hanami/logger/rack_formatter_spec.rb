# frozen_string_literal: true

require "dry/logger"
require "hanami/logger/rack_formatter"
require "stringio"

RSpec.describe Hanami::Logger::RackFormatter do
  def build_logger(stream:, colorize:)
    Dry.Logger(
      :test_app,
      stream: stream,
      level: :debug,
      formatter: described_class,
      colorize: colorize
    )
  end

  def capture(colorize:, verb: "GET", status: 200, path: "/", ip: "127.0.0.1", elapsed: "50µs", length: "-", params: {})
    stream = StringIO.new
    logger = build_logger(stream: stream, colorize: colorize)
    logger.tagged(:rack) { logger.info(verb: verb, status: status, path: path, ip: ip, elapsed: elapsed, length: length, params: params) }
    stream.tap(&:rewind).read
  end

  describe "template structure" do
    context "when colorize: false" do
      it "produces plain text with all rack log attributes" do
        output = capture(colorize: false, path: "/users/123")

        expect(output).not_to match(/\e\[/)
        expect(output).to match(/\A\[test_app\] \[INFO\] \[.*\] GET 200 50µs 127\.0\.0\.1 \/users\/123 -\n\z/)
      end
    end

    context "when colorize: true" do
      it "produces colorized text with all rack log attributes" do
        output = capture(colorize: true, verb: "POST", status: 201, path: "/users", elapsed: "12ms")

        expect(output).to match(/\e\[/)
        expect(strip_ansi(output)).to match(/\A\[test_app\] \[INFO\] \[.*\] POST 201 12ms 127\.0\.0\.1 \/users -\n\z/)
      end
    end
  end

  describe "HTTP verb colorization" do
    {
      "GET" => :green,
      "POST" => :yellow,
      "PUT" => :blue,
      "PATCH" => :blue,
      "DELETE" => :red,
      "HEAD" => :cyan
    }.each do |verb, color|
      it "colorizes #{verb} in #{color}" do
        output = capture(colorize: true, verb: verb)
        colored_verb = Dry::Logger::Formatters::Colors.call(color, verb)

        expect(output).to include(colored_verb)
      end
    end

    it "falls back to gray for unknown verbs" do
      output = capture(colorize: true, verb: "PROPFIND")
      colored_verb = Dry::Logger::Formatters::Colors.call(:gray, "PROPFIND")

      expect(output).to include(colored_verb)
    end
  end

  describe "status code colorization" do
    {
      200 => :green,
      201 => :green,
      301 => :cyan,
      304 => :cyan,
      400 => :yellow,
      404 => :yellow,
      500 => :red,
      503 => :red
    }.each do |status, color|
      it "colorizes #{status} in #{color}" do
        output = capture(colorize: true, status: status)
        colored_status = Dry::Logger::Formatters::Colors.call(color, status)

        expect(output).to include(colored_status)
      end
    end
  end

  describe "path colorization" do
    it "echoes the status color on the path" do
      output = capture(colorize: true, status: 200, path: "/users")
      colored_path = Dry::Logger::Formatters::Colors.call(:green, "/users")

      expect(output).to include(colored_path)
    end

    it "colors the path red when the status is 5xx" do
      output = capture(colorize: true, status: 500, path: "/boom")
      colored_path = Dry::Logger::Formatters::Colors.call(:red, "/boom")

      expect(output).to include(colored_path)
    end

    it "colors the path yellow when the status is 4xx" do
      output = capture(colorize: true, status: 404, path: "/missing")
      colored_path = Dry::Logger::Formatters::Colors.call(:yellow, "/missing")

      expect(output).to include(colored_path)
    end
  end

  describe "params formatting" do
    it "omits the params line when params are empty" do
      output = capture(colorize: false)

      expect(output).to eq(output.lines.first)
    end

    it "renders params on a new indented line when present" do
      output = capture(colorize: false, params: {id: "42", q: "hello"})

      expect(output.lines.length).to eq 2
      expect(output.lines.last).to match(/\A  \{.*id.*42.*q.*hello/)
    end
  end

  describe "severity colorization" do
    it "colorizes severity using the parent formatter's per-level colors" do
      info_output = capture(colorize: true)
      expect(info_output).to include(Dry::Logger::Formatters::Colors.call(:magenta, "INFO"))

      stream = StringIO.new
      logger = build_logger(stream: stream, colorize: true)
      logger.tagged(:rack) { logger.error(verb: "GET", status: 500, path: "/", ip: "127.0.0.1", elapsed: "1ms", length: "-", params: {}) }
      error_output = stream.tap(&:rewind).read
      expect(error_output).to include(Dry::Logger::Formatters::Colors.call(:red, "ERROR"))
    end
  end
end
