require 'test_helper'
require 'lotus/environment'
require 'lotus/commands/server'

describe Lotus::Commands::Server do
  let(:opts) { Hash.new }

  before do
    ENV['LOTUS_HOST'] = nil
    ENV['LOTUS_PORT'] = nil
    ENV['LOTUS_ENV']  = nil
    ENV['RACK_ENV']   = nil

    @env    = Lotus::Environment.new(opts)
    @server = Lotus::Commands::Server.new(@env)
  end

  describe '#options' do
    let(:opts) { { port: "3005", host: 'example.com' } }

    it 'sets the options correctly for rack' do
      @server.options[:Port].must_equal 3005
      @server.options[:Host].must_equal "example.com"
    end

    it 'merges in default values' do
      @server.options[:environment].must_equal 'development'
      @server.options[:config].must_equal "config.ru"
    end
  end

  describe 'host' do
    describe 'when no option is specified' do
      it 'defaults to localhost' do
        @server.options.fetch(:Host).must_equal 'localhost'
      end

      it 'sets an env var for that value' do
        ENV['LOTUS_HOST'].must_equal 'localhost'
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[host: 'lotusrb.dev'] }

      it 'sets that value' do
        @server.options.fetch(:Host).must_equal 'lotusrb.dev'
      end

      it 'sets an env var for that value' do
        ENV['LOTUS_HOST'].must_equal 'lotusrb.dev'
      end
    end
  end

  describe 'port' do
    describe 'when no option is specified' do
      it 'defaults to 2300' do
        @server.options.fetch(:Port).must_equal 2300
      end

      it 'sets an env var for that value' do
        ENV['LOTUS_PORT'].must_equal '2300'
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[port: 4000] }

      it 'sets that value' do
        @server.options.fetch(:Port).must_equal 4000
      end

      it 'sets an env var for that value' do
        ENV['LOTUS_PORT'].must_equal '4000'
      end
    end
  end

  describe 'config' do
    describe 'when no option is specified' do
      it 'defaults to config.ru' do
        @server.options.fetch(:config).must_equal 'config.ru'
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[config: 'test/fixtures/config.ru'] }

      it 'sets that value' do
        @server.options.fetch(:config).must_equal 'test/fixtures/config.ru'
      end
    end
  end

  describe 'environment' do
    describe 'when no option is specified' do
      it 'defaults to development' do
        @server.options.fetch(:environment).must_equal 'development'
      end

      it 'sets env vars with the same value' do
        ENV['LOTUS_ENV'].must_equal 'development'
        ENV['RACK_ENV'].must_equal  'development'
      end
    end

    describe 'when an option is specified via RACK_ENV' do
      before do
        ENV['LOTUS_ENV'] = nil
        ENV['RACK_ENV']  = 'test'
        @env    = Lotus::Environment.new(opts)
        @server = Lotus::Commands::Server.new(@env)
      end

      after do
        ENV['RACK_ENV']  = nil
        ENV['LOTUS_ENV'] = nil
      end

      it 'returns that value' do
        @server.options.fetch(:environment).must_equal 'test'
      end

      it 'sets env vars with the same value' do
        ENV['LOTUS_ENV'].must_equal 'test'
        ENV['RACK_ENV'].must_equal  'test'
      end
    end

    describe 'when an option is specified via LOTUS_ENV' do
      before do
        ENV['RACK_ENV']  = nil
        ENV['LOTUS_ENV'] = 'staging'
        @env    = Lotus::Environment.new(opts)
        @server = Lotus::Commands::Server.new(@env)
      end

      after do
        ENV['RACK_ENV']  = nil
        ENV['LOTUS_ENV'] = nil
      end

      it 'returns that value' do
        @server.options.fetch(:environment).must_equal 'staging'
      end

      it 'sets env vars with the same value' do
        ENV['LOTUS_ENV'].must_equal 'staging'
        ENV['RACK_ENV'].must_equal  'staging'
      end
    end

    describe 'when both the options are specified' do
      before do
        ENV['RACK_ENV']  = 'staging'
        ENV['LOTUS_ENV'] = 'test'
        @env    = Lotus::Environment.new(opts)
        @server = Lotus::Commands::Server.new(@env)
      end

      it 'gives the precendence to LOTUS_ENV' do
        @server.options.fetch(:environment).must_equal 'test'
      end

      it 'sets env vars with the same value' do
        ENV['LOTUS_ENV'].must_equal 'test'
        ENV['RACK_ENV'].must_equal  'test'
      end
    end
  end

  describe 'access log' do
    it 'defaults to empty array' do
      @server.options.fetch(:AccessLog).must_equal []
    end
  end

  describe 'server' do
    describe 'when no option is specified' do
      it 'defaults to nil' do
        @server.options[:server].must_equal nil
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[server: 'puma'] }

      it 'sets that value' do
        @server.options.fetch(:server).must_equal 'puma'
      end
    end
  end

  describe 'debug' do
    describe 'when no option is specified' do
      it 'defaults to nil' do
        @server.options[:debug].must_equal nil
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[debug: 'true'] }

      it 'sets that value' do
        @server.options.fetch(:debug).must_equal 'true'
      end
    end
  end

  describe 'warn' do
    describe 'when no option is specified' do
      it 'defaults to nil' do
        @server.options[:warn].must_equal nil
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[warn: 'true'] }

      it 'sets that value' do
        @server.options.fetch(:warn).must_equal 'true'
      end
    end
  end

  describe 'daemonize' do
    describe 'when no option is specified' do
      it 'defaults to nil' do
        @server.options[:daemonize].must_equal nil
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[daemonize: 'true'] }

      it 'sets that value' do
        @server.options.fetch(:daemonize).must_equal 'true'
      end
    end
  end

  describe 'pid' do
    describe 'when no option is specified' do
      it 'defaults to nil' do
        @server.options[:pid].must_equal nil
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[pid: 'true'] }

      it 'sets that value' do
        @server.options.fetch(:pid).must_equal 'true'
      end
    end
  end

  describe 'code reloading' do
    describe 'when enabled' do
      let(:opts) { Hash[code_reloading: true] }

      it 'uses Shotgun to wrap the application' do
        @server.instance_variable_get(:@app).must_be_kind_of(Shotgun::Loader)
      end
    end

    describe 'when disabled' do
      let(:opts) { Hash[code_reloading: false] }

      it "doesn't use Shotgun" do
        @server.instance_variable_get(:@app).must_be_nil
      end
    end
  end
end
