require 'test_helper'
require 'lotus/commands/console'
require 'irb'

describe Lotus::Commands::Console do
  let(:opts) { Hash.new }
  let(:env)  { Lotus::Environment.new(opts) }
  let(:console) { Lotus::Commands::Console.new(env) }

  describe '#options' do
    it 'merges in default values' do
      console.options[:applications].must_equal 'config/applications.rb'
    end
  end

  describe '#start' do
    describe 'with no config/applications.rb file' do
      it 'raises a LoadError' do
        proc { console.start }.must_raise(LoadError)
      end
    end

    describe 'manually setting the config/applications.rb file' do
      it 'requires applications.rb and starts an IRB session' do
        opts[:applications] = 'test/fixtures/microservices/config/applications.rb'

        IRB.stub :start, -> { @started = true } do
          console.start
          @started.must_equal true

          $LOADED_FEATURES.must_include "#{Dir.pwd}/#{opts[:applications]}"
        end
      end
    end

    describe 'with the default config/applications.rb file' do
      before do
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/microservices'
        $LOAD_PATH.unshift Dir.pwd
      end

      describe 'using IRB' do
        it 'requires applications.rb and starts an IRB session' do
          IRB.stub :start, -> { @started = true } do
            console.start
            @started.must_equal true

            $LOADED_FEATURES.must_include "#{Dir.pwd}/config/applications.rb"
          end
        end
      end

      describe 'using Pry' do
        before do
          unless defined?(::Pry)
            @remove_pry_const = true
            module Pry; def self.start() end; end
          end
        end

        it 'requires applications.rb and starts a Pry session' do
          Pry.stub :start, -> { @started = true } do
            console.start
            @started.must_equal true

            $LOADED_FEATURES.must_include "#{Dir.pwd}/config/applications.rb"
          end
        end

        after do
          Object.send(:remove_const, :Pry) if @remove_pry_const
        end
      end

      after do
        $LOAD_PATH.shift
        Dir.chdir @old_pwd
      end
    end
  end
end
