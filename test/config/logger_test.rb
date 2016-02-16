require 'test_helper'

describe Hanami::Config::Logger do
  let(:logger) { Hanami::Config::Logger.new }
  let(:path) { 'path/to/log/file' }

  describe '#stream' do
    it 'contains steam object' do
      logger.stream(path)
      logger.stream.must_equal path
    end

    it 'contains STDOUT value by default' do
      logger.stream.must_equal STDOUT
    end
  end

  describe '#build' do
    it 'returns new Utils::Logger instance' do
      logger.build.must_be_instance_of Hanami::Logger
    end

    describe 'when stream value is set' do
      it 'returns new Utils::Logger instance with changed log_device' do
        logger.stream(path)
        builded_logger = logger.build

        builded_logger.must_be_instance_of Hanami::Logger
        builded_logger.instance_variable_get("@log_device").must_equal path
      end
    end
  end
end
