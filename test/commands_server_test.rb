require 'test_helper'
require 'lotus/commands/server'

describe Lotus::Commands::Server do
  before do
    @server = Lotus::Commands::Server.new
  end

  describe '#options' do
    let(:new_args) { %w(ignoreme -p 3005) }
    let(:opt_parser) { MiniTest::Mock.new }

    before do
      @regular_args = ARGV.dup
      ARGV.replace(new_args)
    end

    after do
      ARGV.replace(@regular_args)
    end

    it 'sets the environment with correct arguments' do
      @server.options[:Port].must_equal "3005"
    end
  end

  describe '#middleware' do
    it 'does not mount ShowExceptions in deployment' do
      @server.middleware["deployment"]
        .include?(::Rack::ShowExceptions).must_equal false
    end

    it 'does mount ShowExceptions in development' do
      @server.middleware["development"]
        .include?(::Rack::ShowExceptions).must_equal true
    end

    it 'mounts ContentLength middleware' do
      @server.middleware.each do |env, middleware|
        middleware.include?(::Rack::ContentLength).must_equal true
      end
    end
  end
end
