# frozen_string_literal: true

require "hanami/configuration/logger"
require "logger"

RSpec.describe Hanami::Configuration::Logger do
  subject { described_class.new(application_name: application_name, env: env) }
  let(:application_name) { :my_app }
  let(:env) { :development }

  describe "#logger_class" do
    it "defaults to Hanami::Logger" do
      expect(subject.logger_class).to eql Hanami::Logger
    end

    it "can be changed to another class" do
      another_class = Class.new

      expect { subject.logger_class = another_class }
        .to change { subject.logger_class }
        .to(another_class)
    end
  end

  describe "#application_name" do
    it "defaults returns application name" do
      expect(subject.application_name).to eq(application_name)
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
    it "accepts a IO object or a path to a file" do
      expect { subject.stream = "/dev/null" }
        .to change { subject.stream }
        .to("/dev/null")
    end
  end

  describe "#options" do
    it "defaults to {level: :debug}" do
      expect(subject.options).to eq(level: :debug)
    end

    it "can have additional options set" do
      expect { subject.options[:stream] = "/some/file" }
        .to change { subject.options }
        .to(level: :debug, stream: "/some/file")
    end

    it "can be changed to another hash of options" do
      expect { subject.options = {level: :info} }
        .to change { subject.options }
        .to(level: :info)
    end
  end

  describe "#filter_params" do
    it "defaults to a standard array of sensitive param names" do
      expect(subject.filter_params).to include(*%w[_csrf password password_confirmation])
    end

    it "can have other params names added" do
      expect { subject.filter_params << "secret_param" }
        .to change { subject.filter_params }
        .to array_including("secret_param")
    end

    it "can be changed to another array" do
      expect { subject.filter_params = ["secret_param"] }
        .to change { subject.filter_params }
        .to ["secret_param"]
    end
  end
end


RSpec.describe Hanami::Configuration do
  subject(:config) { described_class.new(application_name: application_name, env: env) }
  let(:application_name) { "MyApp::Application" }
  let(:env) { :development }

  describe "#logger" do
    describe "#application_name" do
      it "defaults to Hanami::Configuration#application_name" do
        expect(config.logger.application_name).to eq(config.application_name)
      end
    end
  end

  describe "#logger_instance" do
    it "returns an instance of the configured logger class, with configured options given to its initializer" do
      klass = Struct.new(:opts)

      config.logger.logger_class = klass

      expect(config.logger_instance).to be_an_instance_of klass
      expect(config.logger_instance.opts).to eq config.logger.options
    end

    it "defaults to an Hanami::Logger instance, based on the default logger settings" do
      expect(config.logger_instance).to be_an_instance_of config.logger.logger_class
      expect(config.logger_instance.level).to eq Logger::DEBUG
    end

    it "can be changed to a pre-initialized instance via #logger=" do
      logger_instance = Object.new

      expect { config.logger = logger_instance }
        .to change { config.logger_instance }
        .to logger_instance
    end
  end
end
