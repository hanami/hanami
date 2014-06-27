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

    it 'should set the environment with correct arguments' do
      @server.options[:Port].must_equal "3005"
    end
  end
end
