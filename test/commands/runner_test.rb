require 'test_helper'
require 'hanami/commands/runner'

describe Hanami::Commands::Runner do
  before do
    @old_hanami_env = ENV['HANAMI_ENV']
    ENV['HANAMI_ENV'] = "development"
    Hanami::Application.applications.clear
    @old_pwd = Dir.pwd
    Dir.chdir 'test/fixtures/microservices'
  end

  after do
    ENV['HANAMI_ENV'] = @old_hanami_env
    Dir.chdir @old_pwd
  end

  describe '#start' do
    it 'evaluate expression' do
      command   = Hanami::Commands::Runner.new({}, 'puts Hanami.env')
      output, _ = capture_io { command.start }
      output.chomp.must_equal 'development'
    end

    it 'evaluate ruby file' do
      command   = Hanami::Commands::Runner.new({}, 'apps/backend/scripts/script_001.rb')
      output, _ = capture_io { command.start }
      output.chomp.must_equal 'development'
    end

    it 'evaluate ruby file and return $0' do
      filename  = 'apps/backend/scripts/script_002.rb'
      command   = Hanami::Commands::Runner.new({}, filename)
      output, _ = capture_io { command.start }
      output.chomp.must_equal filename
    end

    it 'no argument given' do
      exception = -> { Hanami::Commands::Runner.new({}, nil) }.must_raise ArgumentError
      exception.message.must_equal "Provide file or expression to execute"
    end
  end
end
