# frozen_string_literal: true

require "hanami/configuration"

RSpec.describe Hanami::Configuration do
  subject(:config) { described_class.new(env: :development) }

  describe "#logger" do
    describe "#logger_class" do
      it "defaults to Hanami::Logger" do
        expect(config.logger.logger_class).to eql Hanami::Logger
      end

      it "can be changed to another class" do
        another_class = Class.new

        expect { config.logger.logger_class = another_class }
          .to change { config.logger.logger_class }
          .to(another_class)
      end
    end

    describe "#options" do
      it "defaults to {level: :debug}" do
        expect(config.logger.options).to eq(level: :debug)
      end

      it "can have additional options set" do
        expect { config.logger.options[:stream] = "/some/file" }
          .to change { config.logger.options }
          .to(level: :debug, stream: "/some/file")
      end

      it "can be changed to another hash of options" do
        expect { config.logger.options = {level: :info} }
          .to change { config.logger.options }
          .to(level: :info)
      end
    end

    describe "#filter_params" do
      it "defaults to a standard array of sensitive param names" do
        expect(config.logger.filter_params).to include(*%w[_csrf password password_confirmation])
      end

      it "can have other params names added" do
        expect { config.logger.filter_params << "secret_param" }
          .to change { config.logger.filter_params }
          .to array_including("secret_param")
      end

      it "can be changed to another array" do
        expect { config.logger.filter_params = ["secret_param"] }
          .to change { config.logger.filter_params }
          .to ["secret_param"]
      end
    end

    describe "#instance" do
      it "defaults to a new Hanami::Logger initialized with the default options" do
        instance = config.logger.instance

        expect(instance).to be_an_instance_of Hanami::Logger
        expect(instance.level).to eq ::Logger::DEBUG
      end

      it "builds a new instance each time" do
        expect(config.logger.instance).not_to be config.logger.instance
      end

      context "providing a prebuilt instance" do
        let(:logger_instance) { Object.new }

        before do
          config.logger.instance = logger_instance
        end

        it "returns the given instance" do
          expect(config.logger.instance).to be logger_instance
        end

        it "returns the given instance each time" do
          expect(config.logger.instance).to be config.logger.instance
        end
      end
    end

    describe "#logger=" do
      it "sets the instance" do
        logger_instance = Object.new

        expect { config.logger = logger_instance }
          .to change { config.logger.instance }
          .to logger_instance
      end

      it "returns the given instance each time" do
        logger_instance = Object.new
        config.logger = logger_instance

        expect(config.logger.instance).to be config.logger.instance
      end
    end
  end
end
