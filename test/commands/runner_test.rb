require 'test_helper'
require 'lotus/commands/runner'

describe Lotus::Commands::Runner do
  before do
    @old_lotus_env = ENV['LOTUS_ENV']
    ENV['LOTUS_ENV'] = "development"
    Lotus::Application.applications.clear
    @old_pwd = Dir.pwd
    Dir.chdir 'test/fixtures/microservices'
  end

  after do
    ENV['LOTUS_ENV'] = @old_lotus_env
    Dir.chdir @old_pwd
  end

  describe '#start' do
    it 'evaluate expression' do
      command   = Lotus::Commands::Runner.new({}, 'puts Lotus.env')
      output, _ = capture_io { command.start }
      output.chomp.must_equal 'development'
    end

    it 'evaluate ruby file' do
      command   = Lotus::Commands::Runner.new({}, 'apps/backend/scripts/script_001.rb')
      output, _ = capture_io { command.start }
      output.chomp.must_equal 'development'
    end

    it 'evaluate ruby file and return $0' do
      filename  = 'apps/backend/scripts/script_002.rb'
      command   = Lotus::Commands::Runner.new({}, filename)
      output, _ = capture_io { command.start }
      output.chomp.must_equal filename
    end

    it 'no argument given' do
      exception = -> { Lotus::Commands::Runner.new({}, nil) }.must_raise ArgumentError
      exception.message.must_equal "Provide file or expression to execute"
    end
  end
end
