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

  describe '#name' do
    it 'contains name' do
      logger.app_name('test_app')
      logger.app_name.must_equal 'test_app'
    end
  end

  describe '#build' do
    it 'returns new Utils::Logger instance' do
      logger.build.must_be_instance_of Hanami::Logger
    end

    describe 'when stream value is set' do
      let(:io) { StringIO.new }

      it 'returns new Utils::Logger instance with changed log_device' do
        logger.stream(io)
        builded_logger = logger.build

        builded_logger.must_be_instance_of Hanami::Logger
        builded_logger.instance_variable_get("@device").must_equal io
      end
    end
  end
end
