# frozen_string_literal: true

require "hanami/config/logger"
require "hanami/slice_name"
require "dry/inflector"
require "logger"
require "stringio"

RSpec.describe Hanami::Config::Logger do
  subject do
    described_class.new(app_name: app_name, env: env)
  end

  let(:app_name) do
    Hanami::SliceName.new(double(name: "MyApp::app"), inflector: -> { Dry::Inflector.new })
  end

  let(:env) { :development }

  describe "#level" do
    it "defaults to :debug" do
      expect(subject.level).to eq(:debug)
    end

    context "when :production environment" do
      let(:env) { :production }

      it "returns :info" do
        expect(subject.level).to eq(:info)
      end
    end
  end

  describe "#level=" do
    it "a value" do
      expect { subject.level = :warn }
        .to change { subject.level }
        .to(:warn)
    end
  end

  describe "#stream" do
    it "defaults to $stdout" do
      expect(subject.stream).to eq($stdout)
    end

    context "when :test environment" do
      let(:env) { :test }

      it "returns a file" do
        expected = File.join("log", "test.log")

        expect(subject.stream).to eq(expected)
      end
    end
  end

  describe "#stream=" do
    it "accepts a path to a file" do
      expect { subject.stream = File::NULL }
        .to change { subject.stream }
        .to(File::NULL)
    end

    it "accepts a IO object" do
      stream = StringIO.new

      expect { subject.stream = stream }
        .to change { subject.stream }
        .to(stream)
    end
  end

  describe "#formatter" do
    it "defaults to :string" do
      expect(subject.formatter).to eq(:string)
    end

    context "when :production environment" do
      let(:env) { :production }

      it "returns :json" do
        expect(subject.formatter).to eq(:json)
      end
    end
  end

  describe "#formatter=" do
    it "accepts a formatter" do
      expect { subject.formatter = :json }
        .to change { subject.formatter }
        .to(:json)
    end
  end

  describe "#template" do
    it "defaults to :details" do
      expect(subject.template).to be(:details)
    end
  end

  describe "#template=" do
    it "accepts a value" do
      expect { subject.template = "%<message>s" }
        .to change { subject.template }
        .to("%<message>s")
    end
  end

  describe "#filters" do
    it "defaults to a standard array of sensitive param names" do
      expect(subject.filters).to include(*%w[_csrf password password_confirmation])
    end

    it "can have other params names added" do
      expect { subject.filters << "secret" }
        .to change { subject.filters }
        .to array_including("secret")

      expect { subject.filters += ["yet", "another"] }
        .to change { subject.filters }
        .to array_including(["yet", "another"])
    end

    it "can be changed to another array" do
      expect { subject.filters = ["secret"] }
        .to change { subject.filters }
        .to ["secret"]
    end
  end

  describe "#options" do
    it "defaults to empty hash" do
      expect(subject.options).to eq({})
    end
  end

  describe "#options=" do
    it "accepts value" do
      subject.options = expected = {rotate: "daily"}

      expect(subject.options).to eq(expected)
    end
  end
end

RSpec.describe Hanami::Config do
  subject(:config) { described_class.new(app_name: app_name, env: env) }

  let(:app_name) do
    Hanami::SliceName.new(double(name: "SOS::app"), inflector: -> { Dry::Inflector.new })
  end

  let(:env) { :development }

  describe "#logger" do
    before do
      config.inflections do |inflections|
        inflections.acronym "SOS"
      end

      config.logger.finalize!
    end

    describe "#app_name" do
      it "defaults to Hanami::Config#app_name" do
        expect(config.logger.app_name).to eq(config.app_name)
      end
    end
  end

  describe "#logger_instance" do
    it "defaults to using Dry::Logger, based on the default logger settings" do
      expect(config.logger_instance).to be_a(Dry::Logger::Dispatcher)
      expect(config.logger_instance.level).to eq Logger::DEBUG
    end

    it "can be changed to a pre-initialized instance via #logger=" do
      logger_instance = Object.new

      expect { config.logger = logger_instance }
        .to change { config.logger_instance }
        .to logger_instance
    end

    context "unrecognized :env" do
      let(:env) { :staging }

      it "provides a fail-safe configuration" do
        expect { config.logger_instance }.to_not raise_error
        expect(config.logger_instance).to be_a(Dry::Logger::Dispatcher)
      end
    end
  end
end
