require 'test_helper'

describe Lotus::Environment do
  before do
    ENV['LOTUS_ENV']  = nil
    ENV['RACK_ENV']   = nil
    ENV['LOTUS_HOST'] = nil
    ENV['LOTUS_PORT'] = nil
  end

  describe '#environment' do
    describe "when LOTUS_ENV is set" do
      before do
        ENV['LOTUS_ENV'] = 'test'
        @env = Lotus::Environment.new
      end

      it 'returns that value' do
        @env.environment.must_equal 'test'
      end
    end

    describe "when RACK_ENV is set" do
      before do
        ENV['RACK_ENV'] = 'production'
        @env = Lotus::Environment.new
      end

      it 'returns that value' do
        @env.environment.must_equal 'production'
      end
    end

    describe "when none is set" do
      before do
        @env = Lotus::Environment.new
      end

      it 'defaults to "development"' do
        @env.environment.must_equal 'development'
      end
    end

    describe "when all are set" do
      before do
        ENV['LOTUS_ENV'] = 'test'
        ENV['RACK_ENV']  = 'production'
        @env = Lotus::Environment.new
      end

      it 'gives the precedence to LOTUS_ENV' do
        @env.environment.must_equal 'test'
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Lotus::Environment.new
      end

      it 'always return the same value' do
        @env.environment.must_equal 'development'

        ENV['LOTUS_ENV'] = 'test'
        @env.environment.must_equal 'development'
      end
    end
  end

  describe '#host' do
    describe "when the correspoding option is set" do
      before do
        @env = Lotus::Environment.new(host: 'lotusrb.test')
      end

      it 'returns that value' do
        @env.host.must_equal 'lotusrb.test'
      end
    end

    describe "when the corresponding option isn't set" do
      describe "and LOTUS_HOST is set" do
        before do
          ENV['LOTUS_HOST'] = 'lotus.host'
          @env = Lotus::Environment.new
        end

        it 'returns that value' do
          @env.host.must_equal 'lotus.host'
        end
      end

      describe "and the current environment is the default one" do
        before do
          @env = Lotus::Environment.new
        end

        it 'returns localhost' do
          @env.host.must_equal 'localhost'
        end
      end

      describe "and the current environment isn't the default" do
        before do
          ENV['LOTUS_ENV'] = 'staging'
          @env = Lotus::Environment.new
        end

        it 'returns 0.0.0.0' do
          @env.host.must_equal '0.0.0.0'
        end
      end

      describe "and all the other env vars are set" do
        before do
          ENV['LOTUS_HOST'] = 'lotushost.test'
          ENV['LOTUS_ENV']  = 'test'
          @env = Lotus::Environment.new
        end

        it 'gives the precedence to LOTUS_HOST' do
          @env.host.must_equal 'lotushost.test'
        end
      end
    end

    describe "when the corresponding option and all the other env vars are set" do
      before do
        ENV['LOTUS_HOST'] = 'lotushost.test'
        ENV['LOTUS_ENV']  = 'test'
        @env = Lotus::Environment.new(host: 'lotusrb.org')
      end

      it 'gives the precedence to the option' do
        @env.host.must_equal 'lotusrb.org'
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Lotus::Environment.new
      end

      it 'always return the same value' do
        @env.host.must_equal 'localhost'

        ENV['LOTUS_HOST'] = 'changedlotushost.org'
        @env.host.must_equal 'localhost'
      end
    end
  end

  describe '#port' do
    describe "when the correspoding option is set" do
      before do
        @env = Lotus::Environment.new(port: 1234)
      end

      it 'returns that value' do
        @env.port.must_equal 1234
      end
    end

    describe "when the corresponding option isn't set" do
      describe "and LOTUS_PORT is set" do
        before do
          ENV['LOTUS_PORT'] = '3244'
          @env = Lotus::Environment.new
        end

        it 'returns that value' do
          @env.port.must_equal 3244
        end
      end

      describe "and no env vars are set" do
        before do
          @env = Lotus::Environment.new
        end

        it 'defaults to 2300' do
          @env.port.must_equal 2300
        end
      end
    end

    describe "when the corresponding option and all the other env vars are set" do
      before do
        ENV['LOTUS_PORT'] = '8206'
        @env = Lotus::Environment.new(port: 2323)
      end

      it 'gives the precedence to the option' do
        @env.port.must_equal 2323
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Lotus::Environment.new
      end

      it 'always return the same value' do
        @env.port.must_equal 2300

        ENV['LOTUS_PORT'] = '1223'
        @env.port.must_equal 2300
      end
    end
  end

  describe '#code_reloading?' do
    describe 'when not specified' do
      describe 'in the default env' do
        before do
          @env = Lotus::Environment.new
        end

        it 'returns true' do
          @env.code_reloading?.must_equal true
        end
      end

      describe 'with a specified env (development)' do
        before do
          ENV['LOTUS_ENV'] = 'development'
          @env = Lotus::Environment.new
        end

        it 'returns true' do
          @env.environment.must_equal 'development'
          @env.code_reloading?.must_equal true
        end
      end

      describe 'with a specified env (test)' do
        before do
          ENV['LOTUS_ENV'] = 'test'
          @env = Lotus::Environment.new
        end

        it 'returns true' do
          @env.environment.must_equal 'test'
          @env.code_reloading?.must_equal false
        end
      end
    end

    describe 'when specified' do
      describe 'with false' do
        before do
          @env = Lotus::Environment.new(code_reloading: false)
        end

        it 'returns false' do
          @env.code_reloading?.must_equal false
        end
      end

      describe 'with true' do
        before do
          @env = Lotus::Environment.new(code_reloading: true)
        end

        it 'returns true' do
          @env.code_reloading?.must_equal true
        end
      end
    end
  end
end
