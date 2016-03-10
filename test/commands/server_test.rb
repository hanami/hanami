require 'test_helper'
require 'hanami/environment'
require 'hanami/commands/server'

describe Hanami::Commands::Server do
  let(:opts) { Hash.new }

  before do
    ENV['HANAMI_HOST'] = nil
    ENV['HANAMI_PORT'] = nil
    ENV['HANAMI_ENV']  = nil
    ENV['RACK_ENV']   = nil


    class Hanami::Commands::Server
      def entr_enabled?
        false
      end
    end

    @server = Hanami::Commands::Server.new(opts).server
  end

  describe '#middleware' do
    it 'returns per env Rack stack' do
      expected = {
        'deployment'  => [::Rack::ContentLength, ::Rack::CommonLogger],
        'development' => [::Rack::ContentLength, ::Rack::CommonLogger,
                          ::Rack::ShowExceptions, Rack::Lint]
      }

      @server.middleware.must_equal(expected)
    end
  end

  describe '#options' do
    let(:opts) { { port: "3005", host: 'example.com' } }

    it 'sets the options correctly for rack' do
      @server.options[:Port].must_equal 3005
      @server.options[:Host].must_equal "example.com"
    end

    it 'merges in default values' do
      @server.options[:environment].must_equal 'development'
      @server.options[:config].must_equal Pathname.new('config.ru').expand_path.to_s
    end
  end

  describe 'host' do
    describe 'when no option is specified' do
      it 'defaults to localhost' do
        @server.options.fetch(:Host).must_equal 'localhost'
      end

      it 'sets an env var for that value' do
        ENV['HANAMI_HOST'].must_equal 'localhost'
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[host: 'hanamirb.dev'] }

      it 'sets that value' do
        @server.options.fetch(:Host).must_equal 'hanamirb.dev'
      end

      it 'sets an env var for that value' do
        ENV['HANAMI_HOST'].must_equal 'hanamirb.dev'
      end
    end
  end

  describe 'port' do
    describe 'when no option is specified' do
      it 'defaults to 2300' do
        @server.options.fetch(:Port).must_equal 2300
      end

      it 'sets an env var for that value' do
        ENV['HANAMI_PORT'].must_equal '2300'
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[port: 4000] }

      it 'sets that value' do
        @server.options.fetch(:Port).must_equal 4000
      end

      it 'sets an env var for that value' do
        ENV['HANAMI_PORT'].must_equal '4000'
      end
    end
  end

  describe 'rackup file (aka "config" for Rack configurations)' do
    describe 'when no option is specified' do
      it 'defaults to config.ru' do
        @server.options.fetch(:config).must_equal Pathname.new('config.ru').expand_path.to_s
      end
    end

    describe 'when an option is specified' do
      let(:opts) { Hash[rackup: 'test/fixtures/config.ru'] }

      it 'sets that value' do
        @server.options.fetch(:config).must_equal Pathname.new('test/fixtures/config.ru').expand_path.to_s
      end
    end
  end

  describe 'environment' do
    describe 'when no option is specified' do
      it 'defaults to development' do
        @server.options.fetch(:environment).must_equal 'development'
      end

      it 'sets env vars with the same value' do
        ENV['HANAMI_ENV'].must_equal 'development'
        ENV['RACK_ENV'].must_equal  'development'
      end
    end

    describe 'when an option is specified via RACK_ENV' do
      before do
        ENV['HANAMI_ENV'] = nil
        ENV['RACK_ENV']  = 'test'
        @server = Hanami::Commands::Server.new(opts).server
      end

      after do
        ENV['RACK_ENV']  = nil
        ENV['HANAMI_ENV'] = nil
      end

      it 'returns that value' do
        @server.options.fetch(:environment).must_equal 'test'
      end

      it 'sets env vars with the same value' do
        ENV['HANAMI_ENV'].must_equal 'test'
        ENV['RACK_ENV'].must_equal  'test'
      end
    end

    describe 'when an option is specified via HANAMI_ENV' do
      before do
        ENV['RACK_ENV']  = nil
        ENV['HANAMI_ENV'] = 'staging'
        @server = Hanami::Commands::Server.new(opts).server
      end

      after do
        ENV['RACK_ENV']  = nil
        ENV['HANAMI_ENV'] = nil
      end

      it 'returns that value' do
        @server.options.fetch(:environment).must_equal 'staging'
      end

      it 'sets env vars with the same value' do
        ENV['HANAMI_ENV'].must_equal 'staging'
        ENV['RACK_ENV'].must_equal  'staging'
      end
    end

    describe 'when both the options are specified' do
      before do
        ENV['RACK_ENV']  = 'staging'
        ENV['HANAMI_ENV'] = 'test'
        @server = Hanami::Commands::Server.new(opts).server
      end

      it 'gives the precendence to HANAMI_ENV' do
        @server.options.fetch(:environment).must_equal 'test'
      end

      it 'sets env vars with the same value' do
        ENV['HANAMI_ENV'].must_equal 'test'
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

  describe 'code reloading', engine: :mri do
    describe 'when reloading enabled' do

      describe 'shotgun disabled' do
        before do
          @server_klass = Class.new(Hanami::Commands::Server) do
            def shotgun_enabled?
              false
            end
          end

          @server = @server_klass.new(opts).server
        end

        let(:opts) { Hash[code_reloading: true] }

        it "doesn't use Shotgun" do
          @server.instance_variable_get(:@app).must_be_nil
        end
      end

      describe 'shotgun enabled' do
        let(:opts) { Hash[code_reloading: true] }

        it 'uses Shotgun to wrap the application' do
          @server.instance_variable_get(:@app).must_be_kind_of(Shotgun::Loader)
        end
      end

      describe 'fork not support' do
        before do

          @server_klass = Class.new(Hanami::Commands::Server) do
            def fork_supported?
              false
            end
          end

          @server = @server_klass.new(opts).server
        end

        let(:opts) { Hash[code_reloading: true] }

        it "doesn't use Shotgun" do
          @server.instance_variable_get(:@app).must_be_nil
        end
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
