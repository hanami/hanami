# frozen_string_literal: true

require "dry/logger"
require "hanami/logger/sql_formatter"
require "stringio"

RSpec.describe Hanami::Logger::SQLFormatter do
  # Strips ANSI escape sequences for plain-text assertions.
  def strip_ansi(str)
    str.gsub(/\e\[[0-9;]*m/, "")
  end

  # Returns true when the string contains the 256-colour escape sequences emitted by
  # Rouge::Formatters::Terminal256 (e.g. "\e[38;5;203m").
  def rouge_highlighted?(str)
    str.match?(/\e\[38;5;\d+m/)
  end

  def build_logger(stream:, colorize:)
    Dry.Logger(
      :test_app,
      stream: stream,
      level: :debug,
      formatter: described_class,
      colorize: colorize
    )
  end

  def capture(colorize:, query: "SELECT id FROM posts", db: :sqlite, elapsed: 1.234, elapsed_unit: "ms")
    stream = StringIO.new
    logger = build_logger(stream: stream, colorize: colorize)
    logger.tagged(:sql) { logger.info(query: query, db: db, elapsed: elapsed, elapsed_unit: elapsed_unit) }
    stream.tap(&:rewind).read
  end

  describe "log output format" do
    context "when colorize: false" do
      it "produces plain text with all SQL log attributes" do
        output = capture(colorize: false, query: "SELECT id FROM posts", db: :sqlite, elapsed: 1.234)

        expect(output).not_to match(/\e\[/)
        expect(output).to match(/\A\[test_app\] \[INFO\] \[.*\] SQL sqlite 1\.234ms SELECT id FROM posts\n\z/)
      end
    end

    context "when colorize: true" do
      it "produces colorized text with all SQL log attributes" do
        output = capture(colorize: true, query: "SELECT id FROM posts", db: :postgres, elapsed: 0.5)

        expect(output).to match(/\e\[/)
        expect(strip_ansi(output)).to match(/\A\[test_app\] \[INFO\] \[.*\] SQL postgres 0\.5ms SELECT id FROM posts\n\z/)
      end
    end
  end

  describe "SQL syntax highlighting using Rouge" do
    context "when rouge is available" do
      it "applies Rouge 256-colour highlighting when colorize: true" do
        expect(rouge_highlighted?(capture(colorize: true))).to be true
      end

      it "does not apply Rouge highlighting when colorize: false" do
        expect(rouge_highlighted?(capture(colorize: false))).to be false
      end

      it "preserves the full query text through highlighting" do
        sql = "SELECT posts.title FROM posts WHERE posts.id = 42"
        expect(strip_ansi(capture(colorize: true, query: sql))).to include(sql)
      end

      it "handles an empty query string without raising" do
        expect { capture(colorize: true, query: "") }.not_to raise_error
      end
    end

    context "when rouge is not available" do
      def capture_without_rouge(**opts)
        allow_any_instance_of(described_class)
          .to receive(:require)
          .with("rouge")
          .and_raise(LoadError, "cannot load such file -- rouge")

        capture(colorize: true, **opts)
      end

      it "outputs the query as plain text" do
        output = capture_without_rouge(query: "SELECT 1")

        expect(strip_ansi(output)).to include("SELECT 1")
        expect(rouge_highlighted?(output)).to be false
      end
    end
  end

  describe "HANAMI_SQL_THEME environment variable" do
    around do |example|
      original = ENV["HANAMI_SQL_THEME"]
      example.run
    ensure
      ENV["HANAMI_SQL_THEME"] = original
    end

    it "uses the named theme when HANAMI_SQL_THEME is set to a valid theme name" do
      default_output = capture(colorize: true)

      ENV["HANAMI_SQL_THEME"] = "monokai"
      monokai_output = capture(colorize: true)

      # Both should be highlighted, but with different colour codes
      expect(rouge_highlighted?(monokai_output)).to be true
      expect(monokai_output).not_to eq(default_output)
    end

    it "falls back to Gruvbox without raising when HANAMI_SQL_THEME names an unknown theme" do
      ENV["HANAMI_SQL_THEME"] = "totally_nonexistent_theme"

      expect { capture(colorize: true) }.not_to raise_error
      expect(rouge_highlighted?(capture(colorize: true))).to be true
    end
  end
end
