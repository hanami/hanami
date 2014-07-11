require 'test_helper'
require 'lotus/commands/console'

describe Lotus::Commands::Console do
  let(:opts) { Hash.new }
  let(:env)  { Lotus::Environment.new(opts) }
  let(:console) { Lotus::Commands::Console.new(env) }

  def stub_engine(engine)
    begin
      @engine = Object.const_get(engine)
    rescue NameError
      @remove_const = true
    end

    Lotus::Utils::IO.silence_warnings do
      Object.const_set(engine, Module.new { def self.start; end })
    end
  end

  def remove_engine(engine)
    Lotus::Utils::IO.silence_warnings do
      Object.const_set(engine, @engine)
    end if @engine

    Object.send(:remove_const, engine.to_sym) if @remove_const
  end

  describe '#options' do
    describe "when no options are specified" do
      it 'returns a default' do
        console.options.fetch(:applications).must_equal 'config/applications'
      end
    end

    describe "when :applications option is specified" do
      let(:opts) { Hash[applications: 'path/to/applications'] }

      it 'returns that value' do
        console.options.fetch(:applications).must_equal 'path/to/applications'
      end
    end
  end

  describe '#engine' do
    describe 'when all the supported engines are loaded' do
      before do
        stub_engine 'Pry'
        stub_engine 'Ripl'
        stub_engine 'IRB'
      end

      after do
        remove_engine 'Pry'
        remove_engine 'Ripl'
        remove_engine 'IRB'
      end

      it 'prefers Pry' do
        console.engine.must_equal(Pry)
      end
    end

    describe 'when Ripl and IRB are loaded' do
      before do
        stub_engine 'Ripl'
        stub_engine 'IRB'
      end

      after do
        remove_engine 'Ripl'
        remove_engine 'IRB'
      end

      it 'prefers Ripl' do
        console.engine.must_equal(Ripl)
      end
    end

    describe 'when nothing is loaded' do
      before do
        stub_engine 'IRB'
      end

      after do
        remove_engine 'IRB'
      end

      it 'uses IRB' do
        console.engine.must_equal(IRB)
      end
    end

    describe 'when an option forces to use a specific engine' do
      describe 'IRB' do
        let(:opts) { Hash[engine: 'irb'] }

        before do
          stub_engine 'IRB'
        end

        after do
          remove_engine 'IRB'
        end

        it 'uses IRB' do
          console.engine.must_equal(IRB)
        end
      end

      describe 'Pry' do
        before do
          stub_engine 'Pry'
        end

        after do
          remove_engine 'Pry'
        end

        let(:opts) { Hash[engine: 'pry'] }

        it 'uses Pry' do
          console.engine.must_equal(Pry)
        end
      end

      describe 'Ripl' do
        before do
          stub_engine 'Ripl'
        end

        after do
          remove_engine 'Ripl'
        end

        let(:opts) { Hash[engine: 'ripl'] }

        it 'uses Ripl' do
          console.engine.must_equal(Ripl)
        end
      end

      describe 'Unknown engine' do
        let(:opts) { Hash[engine: 'unknown'] }

        it 'raises error' do
          begin
            console.engine
          rescue ArgumentError => e
            e.message.must_equal 'Unknown console engine: unknown'
          end
        end
      end
    end
  end

  describe '#start' do
    before do
      @engine = Minitest::Mock.new
      @engine.expect(:start, nil)
    end

    describe 'with the default config/applications.rb file' do
      before do
        @old_pwd = Dir.pwd
        Dir.chdir 'test/fixtures/microservices'
      end

      after do
        Dir.chdir @old_pwd
      end

      it 'requires that file and starts a console session' do
        console.stub :engine, @engine do
          console.start

          @engine.verify
          $LOADED_FEATURES.must_include "#{Dir.pwd}/config/applications.rb"
        end
      end
    end

    describe 'when manually setting the applications file' do
      let(:opts) {
        Hash[applications: 'test/fixtures/microservices/config/applications']
      }

      it 'requires that file and starts a console session' do
        console.stub :engine, @engine do
          console.start

          @engine.verify
          $LOADED_FEATURES.must_include "#{Dir.pwd}/#{opts[:applications]}.rb"
        end
      end
    end

    describe 'when applications file is missing' do
      it 'raises a LoadError' do
        console.stub :engine, @engine do
          proc { console.start }.must_raise(LoadError)
        end
      end
    end
  end

  describe 'convenience methods' do
    before do
      @old_main = TOPLEVEL_BINDING
      @main     = Minitest::Mock.new
      Lotus::Utils::IO.silence_warnings { TOPLEVEL_BINDING = @main }
      @main.expect(:eval, TOPLEVEL_BINDING, ['self'])

      @engine = Minitest::Mock.new
      @engine.expect(:start, nil)
    end

    after do
      Lotus::Utils::IO.silence_warnings { TOPLEVEL_BINDING = @old_main }
    end

    it 'mixes convenience methods into the TOPLEVEL_BINDING' do
      @main.expect(:include, true, [Lotus::Commands::Console::Methods])

      opts[:applications] = 'test/fixtures/microservices/config/applications'
      console.stub(:engine, @engine) { console.start }

      @engine.verify
      @main.verify
    end
  end
end

describe Lotus::Commands::Console::Methods do
  describe '#reload!' do
    before do
      @binding = Class.new
      @binding.send(:include, Lotus::Commands::Console::Methods)

      @old_kernel = Kernel
      Lotus::Utils::IO.silence_warnings { Kernel = Minitest::Mock.new }
      Kernel.expect(:exec, true, [$0])
    end

    after do
      Lotus::Utils::IO.silence_warnings { Kernel = @old_kernel }
    end

    it 're-executes the running process' do
      begin
        $stdout = StringIO.new
        @binding.new.reload!
      ensure
        $stdout = STDOUT
      end

      Kernel.verify
    end
  end
end
