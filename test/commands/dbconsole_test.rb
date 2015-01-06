require 'test_helper'
require 'lotus/commands/dbconsole'

describe Lotus::Commands::DBConsole do
  let(:opts) { Hash.new }
  let(:env)  { Lotus::Environment.new(opts) }
  let(:dbconsole) { Lotus::Commands::DBConsole.new(env) }

  before do
    Lotus::Application.clear_registered_applications!
  end

  describe '#options' do
    describe "when no options are specified" do
      it 'returns a default' do
        dbconsole.options.fetch(:env_config).must_equal Pathname.new(Dir.pwd).join('config/environment')
      end
    end

    describe "when :environment option is specified" do
      let(:opts) { Hash[environment: 'path/to/environment'] }

      it 'returns that value' do
        dbconsole.options.fetch(:env_config).must_equal Pathname.new(Dir.pwd).join('path/to/environment')
      end
    end
  end

  describe '#start' do
    describe 'with the default config/environment.rb file' do
      before do
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/microservices'
      end

      after do
        Dir.chdir @old_pwd
      end

      it 'requires that file and starts a dbconsole session' do
        dbconsole.start

        Lotus::Application.applications.count.must_equal 2
        $LOADED_FEATURES.must_include "#{Dir.pwd}/config/environment.rb"
      end
    end

    describe 'with no app specified' do

    end

  end
end
