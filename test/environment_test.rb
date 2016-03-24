require 'test_helper'

describe Hanami::Environment do
  before do
    ENV['HANAMI_ENV']  = nil
    ENV['RACK_ENV']    = nil
    ENV['HANAMI_HOST'] = nil
    ENV['HANAMI_PORT'] = nil

    ENV['FOO'] = nil
    ENV['BAZ'] = nil
    ENV['WAT'] = nil
  end

  describe '#initialize' do
    describe 'env vars' do
      before do
        Dir.chdir($pwd + '/test/fixtures')
        @env = Hanami::Environment.new
      end

      after do
        Dir.chdir($pwd)
      end

      describe 'ignores .env' do
        it 'does not sets env vars' do
          ENV['FOO'].must_be_nil
        end

        it 'does not sets port' do
          @env.port.must_equal 2300
        end
      end

      describe 'environment .env' do
        before do
          Dir.chdir($pwd + '/test/fixtures/dotenv')
          @env = Hanami::Environment.new
        end

        it 'sets port' do
          @env.port.must_equal 42
        end

        it 'sets env vars' do
          ENV['BAZ'].must_equal 'yes'
          ENV['WAT'].must_equal 'true'
        end
      end

      describe 'when the .env is missing' do
        before do
          Dir.chdir($pwd)

          ENV['FOO'] = nil
          ENV['BAZ'] = nil

          @env = Hanami::Environment.new
        end

        it "doesn't set env vars" do
          ENV['FOO'].must_be_nil
          ENV['BAZ'].must_be_nil
        end
      end

      describe 'when the .env for the current environment is missing' do
        before do
          ENV['HANAMI_ENV'] = 'test'
          ENV['BAZ'] = nil
          ENV['WAT'] = nil

          @env = Hanami::Environment.new
        end

        it "doesn't set env vars" do
          ENV['WAT'].must_be_nil
        end
      end

      describe 'when arguments are passed in' do
        before do
          @options = {'a' => 'b'}
          @env = Hanami::Environment.new(@options)
        end

        it 'does not modify the origin arguments' do
          @options['a'].wont_equal nil
        end
      end
    end
  end

  describe '#environment' do
    describe "when HANAMI_ENV is set" do
      before do
        ENV['HANAMI_ENV'] = 'test'
        @env = Hanami::Environment.new
      end

      it 'returns that value' do
        @env.environment.must_equal 'test'
      end
    end

    describe "when RACK_ENV is set to 'production'" do
      before do
        ENV['RACK_ENV'] = 'production'
        @env = Hanami::Environment.new
      end

      it 'returns that value' do
        @env.environment.must_equal 'production'
      end
    end

    describe "when RACK_ENV is set to 'deployment'" do
      before do
        ENV['RACK_ENV'] = 'deployment'
        @env = Hanami::Environment.new
      end

      it 'returns that value' do
        @env.environment.must_equal 'production'
      end
    end

    describe "when none is set" do
      before do
        @env = Hanami::Environment.new
      end

      it 'defaults to "development"' do
        @env.environment.must_equal 'development'
      end
    end

    describe "when all are set" do
      before do
        ENV['HANAMI_ENV'] = 'test'
        ENV['RACK_ENV']  = 'production'
        @env = Hanami::Environment.new
      end

      it 'gives the precedence to HANAMI_ENV' do
        @env.environment.must_equal 'test'
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Hanami::Environment.new
      end

      it 'always returns the same value' do
        @env.environment.must_equal 'development'

        ENV['HANAMI_ENV'] = 'test'
        @env.environment.must_equal 'development'
      end
    end

  end

  describe '#environment?' do
    describe 'when environment is matched' do
      before do
        ENV['HANAMI_ENV'] = 'test'
        @env = Hanami::Environment.new
      end

      describe 'when single name' do
        describe 'when environment var is symbol' do
          it 'returns true' do
            @env.environment?(:test).must_equal true
          end
        end
        describe 'when environment var is string' do
          it 'returns true' do
            @env.environment?("test").must_equal true
          end
        end
      end

      describe 'when multiple names' do
        describe 'when environment vars are symbol' do
          it 'returns true' do
            @env.environment?(:development, :test, :production).must_equal true
          end
        end
        describe 'when environment vars are string' do
          it 'returns true' do
            @env.environment?("development", "test", "production").must_equal true
          end
        end

        describe 'when environment vars include string and symbol' do
          it 'returns true' do
            @env.environment?(:development, "test", "production").must_equal true
          end
        end
      end
    end

    describe 'when environment is not matched' do
      before do
        ENV['HANAMI_ENV'] = 'development'
        @env = Hanami::Environment.new
      end

      describe 'when single name' do
        describe 'when environment var is symbol' do
          it 'returns false' do
            @env.environment?(:test).must_equal false
          end
        end
        describe 'when environment var is string' do
          it 'returns false' do
            @env.environment?("test").must_equal false
          end
        end
      end

      describe 'when multiple names' do
        describe 'when environment vars are symbol' do
          it 'returns false' do
            @env.environment?(:test, :production).must_equal false
          end
        end
        describe 'when environment vars are string' do
          it 'returns false' do
            @env.environment?("test", "production").must_equal false
          end
        end

        describe 'when environment vars include string and symbol' do
          it 'returns false' do
            @env.environment?(:test, "production").must_equal false
          end
        end
      end
    end
  end

  describe '#bundler_groups' do
    before do
      @env = Hanami::Environment.new
    end

    it 'returns a set of groups for Bundler' do
      @env.bundler_groups.must_equal [:default, @env.environment]
    end

  end

  describe '#config' do
    describe 'when not specified' do
      before do
        @env = Hanami::Environment.new
      end

      it 'equals to "config/"' do
        @env.config.must_equal(Pathname.new(Dir.pwd).join('config'))
      end
    end

    describe 'when specified' do
      describe 'and it is relative path' do
        before do
          @env = Hanami::Environment.new(config: 'test')
        end

        it 'equals to it' do
          @env.config.must_equal(Pathname.new(Dir.pwd).join('test'))
        end
      end

      describe 'and it is absolute path' do
        before do
          @path = File.expand_path(__dir__) + '/tmp/config'
          @env  = Hanami::Environment.new(config: @path)
        end

        it 'equals to it' do
          @env.config.must_equal(Pathname.new(@path))
        end
      end
    end
  end

  describe '#env_config' do
    describe 'when not specified' do
      before do
        @env = Hanami::Environment.new
      end

      it 'equals to "config/environment"' do
        @env.env_config.must_equal(Pathname.new(Dir.pwd).join('config/environment'))
      end
    end

    describe 'when specified' do
      describe 'and it is relative path' do
        before do
          @env = Hanami::Environment.new(environment: 'env.rb')
        end

        it 'assumes it is located under root' do
          @env.env_config.must_equal(Pathname.new(Dir.pwd).join('env.rb'))
        end
      end

      describe 'and it is absolute path' do
        before do
          @path = File.expand_path(__dir__) + '/c/env.rb'
          @env  = Hanami::Environment.new(environment: @path)
        end

        it 'assumes it is located under root' do
          @env.env_config.must_equal(Pathname.new(@path))
        end
      end
    end
  end

  describe '#rackup' do
    describe 'when not specified' do
      before do
        @env = Hanami::Environment.new
      end

      it 'equals to "config.ru"' do
        @env.rackup.must_equal(Pathname.new(Dir.pwd).join('config.ru'))
      end
    end

    describe 'when specified' do
      describe 'and it is relative path' do
        before do
          @env = Hanami::Environment.new(rackup: 'test.ru')
        end

        it 'assumes it is located under root' do
          @env.rackup.must_equal(Pathname.new(Dir.pwd).join('test.ru'))
        end
      end

      describe 'and it is absolute path' do
        before do
          @path = File.expand_path(__dir__) + '/absolute.ru'
          @env  = Hanami::Environment.new(rackup: @path)
        end

        it 'assumes it is located under root' do
          @env.rackup.must_equal(Pathname.new(@path))
        end
      end
    end
  end

  describe '#host' do
    describe "when the correspoding option is set" do
      before do
        @env = Hanami::Environment.new(host: 'hanamirb.test')
      end

      it 'returns that value' do
        @env.host.must_equal 'hanamirb.test'
      end
    end

    describe "when the corresponding option isn't set" do
      describe "and HANAMI_HOST is set" do
        before do
          ENV['HANAMI_HOST'] = 'hanami.host'
          @env = Hanami::Environment.new
        end

        it 'returns that value' do
          @env.host.must_equal 'hanami.host'
        end
      end

      describe "and the current environment is the default one" do
        before do
          @env = Hanami::Environment.new
        end

        it 'returns localhost' do
          @env.host.must_equal 'localhost'
        end
      end

      describe "and the current environment isn't the default" do
        before do
          ENV['HANAMI_ENV'] = 'staging'
          @env = Hanami::Environment.new
        end

        it 'returns 0.0.0.0' do
          @env.host.must_equal '0.0.0.0'
        end
      end

      describe "and all the other env vars are set" do
        before do
          ENV['HANAMI_HOST'] = 'hanamihost.test'
          ENV['HANAMI_ENV']  = 'test'
          @env = Hanami::Environment.new
        end

        it 'gives the precedence to HANAMI_HOST' do
          @env.host.must_equal 'hanamihost.test'
        end
      end
    end

    describe "when the corresponding option and all the other env vars are set" do
      before do
        ENV['HANAMI_HOST'] = 'hanamihost.test'
        ENV['HANAMI_ENV']  = 'test'
        @env = Hanami::Environment.new(host: 'hanamirb.org')
      end

      it 'gives the precedence to the option' do
        @env.host.must_equal 'hanamirb.org'
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Hanami::Environment.new
      end

      it 'always return the same value' do
        @env.host.must_equal 'localhost'

        ENV['HANAMI_HOST'] = 'changedhanamihost.org'
        @env.host.must_equal 'localhost'
      end
    end
  end

  describe '#port' do
    describe "when the correspoding option is set" do
      before do
        @env = Hanami::Environment.new(port: 1234)
      end

      it 'returns that value' do
        @env.port.must_equal 1234
      end
    end

    describe "when the corresponding option isn't set" do
      describe "and HANAMI_PORT is set" do
        before do
          ENV['HANAMI_PORT'] = '3244'
          @env = Hanami::Environment.new
        end

        it 'returns that value' do
          @env.port.must_equal 3244
        end
      end

      describe "and no env vars are set" do
        before do
          @env = Hanami::Environment.new
        end

        it 'defaults to 2300' do
          @env.port.must_equal 2300
        end
      end
    end

    describe "when the corresponding option and all the other env vars are set" do
      before do
        ENV['HANAMI_PORT'] = '8206'
        @env = Hanami::Environment.new(port: 2323)
      end

      it 'gives the precedence to the option' do
        @env.port.must_equal 2323
      end
    end

    describe "when the env vars change after the initialization" do
      before do
        @env = Hanami::Environment.new
      end

      it 'always return the same value' do
        @env.port.must_equal 2300

        ENV['HANAMI_PORT'] = '1223'
        @env.port.must_equal 2300
      end
    end
  end

  describe '#code_reloading?', engine: :mri do
    describe 'when not specified' do
      describe 'in the default env' do
        before do
          @env = Hanami::Environment.new
        end

        it 'returns true' do
          @env.code_reloading?.must_equal true
        end
      end

      describe 'with a specified env (development)' do
        before do
          ENV['HANAMI_ENV'] = 'development'
          @env = Hanami::Environment.new
        end

        it 'returns true' do
          @env.environment.must_equal 'development'
          @env.code_reloading?.must_equal true
        end
      end

      describe 'with a specified env (test)' do
        before do
          ENV['HANAMI_ENV'] = 'test'
          @env = Hanami::Environment.new
        end

        it 'returns false' do
          @env.environment.must_equal 'test'
          @env.code_reloading?.must_equal false
        end
      end
    end

    describe 'when specified' do
      describe 'with false' do
        before do
          @env = Hanami::Environment.new(code_reloading: false)
        end

        it 'returns false' do
          @env.code_reloading?.must_equal false
        end
      end

      describe 'with true' do
        before do
          @env = Hanami::Environment.new(code_reloading: true)
        end

        it 'returns true' do
          @env.code_reloading?.must_equal true
        end
      end
    end
  end

  describe 'hanamirc' do
    describe 'with existing file' do
      before do
        @old_pwd = Dir.pwd

        # This .hanamirc has test=minitest
        path = Pathname.new('test/fixtures/hanamirc/exists')
        path.mkpath
        Dir.chdir(path)
      end

      after do
        Dir.chdir @old_pwd
      end

      it 'uses defaults if no inline args' do
        env = Hanami::Environment.new
        env.to_options.fetch(:test).must_equal 'minitest'
      end

      it 'gives priority to inline args' do
        # Simulate hanami new bookshelf --test=rspec
        env = Hanami::Environment.new(test: 'rspec')
        env.to_options.fetch(:test).must_equal 'rspec'
      end
    end

    describe 'with unexisting file' do
      before do
        @old_pwd = Dir.pwd

        path = Pathname.new('test/fixtures/hanamirc/no_exists')
        path.mkpath

        Dir.chdir(path)

        @env = Hanami::Environment.new
      end

      after do
        Dir.chdir @old_pwd
      end

      it 'uses defaults if no inline args' do
        env = Hanami::Environment.new
        env.to_options.fetch(:test).must_equal 'minitest'
      end

      it 'gives priority to inline args' do
        # Simulate hanami new bookshelf --test=rspec
        env = Hanami::Environment.new(test: 'rspec')
        env.to_options.fetch(:test).must_equal 'rspec'
      end
    end
  end

  describe '#to_options' do
    before do
      @old_pwd = Dir.pwd
      path = Pathname.new('test/fixtures/hanamirc/exists')
      path.mkpath
      Dir.chdir(path)
      @env = Hanami::Environment.new
    end

    after do
      Dir.chdir @old_pwd
    end

    it 'hanamirc merge options in environemnt options' do
      options = @env.to_options
      options[:architecture].must_equal 'container'
      options[:test].must_equal 'minitest'
      options[:template].must_equal 'erb'
    end
  end
end
