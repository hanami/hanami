require 'test_helper'

describe Hanami::Config::Logger do
  let(:logger) { Hanami::Config::Logger.new }
  let(:path) { 'path/to/log/file' }

  describe '#stream' do
    it 'contains a stream object' do
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

  describe '#engine' do
    let(:engine) { ::Logger.new(STDOUT) }

    it 'contains name' do
      logger.engine(engine)
      logger.engine.must_equal engine
    end

    it 'contains nil by default' do
      logger.engine.must_equal nil
    end
  end

  describe '#level' do
    it 'delegates to Hanami::Logger when level is integer' do
      logger.level(0)
      logger.build.level.must_equal Hanami::Logger::DEBUG
    end

    it 'delegates to Hanami::Logger when level is symbol' do
      logger.level(:debug)
      logger.build.level.must_equal Hanami::Logger::DEBUG
    end

    it 'delegates to Hanami::Logger when level is string' do
      logger.level('debug')
      logger.build.level.must_equal Hanami::Logger::DEBUG
    end

    it 'delegates to Hanami::Logger when level is upcased string' do
      logger.level('DEBUG')
      logger.build.level.must_equal Hanami::Logger::DEBUG
    end

    it 'delegates to Hanami::Logger when level is a constant' do
      logger.level(Hanami::Logger::DEBUG)
      logger.build.level.must_equal Hanami::Logger::DEBUG
    end

    it 'uses default Hanami::Logger level' do
      logger.build.level.must_equal ::Logger::DEBUG
    end
  end

  describe '#build' do
    it 'returns new Hanami::Logger instance' do
      logger.build.must_be_instance_of Hanami::Logger
    end

    describe 'when stream value is set' do
      let(:io) { StringIO.new }

      it 'returns new Hanami::Logger instance with changed stream' do
        logger.stream(io)
        builded_logger = logger.build

        builded_logger.must_be_instance_of Hanami::Logger
        builded_logger.instance_variable_get("@stream").must_equal io
      end
    end

    describe 'when user set engine' do
      it 'returns it' do
        logger.engine(::Logger.new(STDOUT))
        builded_logger = logger.build

        builded_logger.must_be_instance_of ::Logger
      end
    end

    describe 'when user sets level' do
      it 'returns it' do
        logger.level(:error)
        builded_logger = logger.build

        builded_logger.level.must_equal Hanami::Logger::ERROR
      end
    end
  end
end
