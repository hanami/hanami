require 'test_helper'

describe Lotus::Configuration do
  before do
    @configuration = Lotus::Configuration.new
  end

  describe '#initialize' do
    describe 'when block is given' do
      it 'yields it' do
        configuration = Lotus::Configuration.new do
          root __dir__
        end

        configuration.root.wont_be_nil
      end
    end

    describe 'when no block is given' do
      it 'yields it' do
        configuration = Lotus::Configuration.new
        configuration.root.must_be_nil
      end
    end
  end

  describe '#root' do
    describe 'when a value is given' do
      describe "and it's a string" do
        let(:root) { '..' }

        it 'expand it to the real path' do
          @configuration.root root
          @configuration.root.must_equal Pathname.new(root).realpath
        end
      end

      describe "and it's a pathname" do
        let(:root) { Pathname.new('../..') }

        it 'expand it to the real path' do
          @configuration.root root
          @configuration.root.must_equal Pathname.new(root).realpath
        end
      end

      describe "and it implements to_pathname" do
        before do
          class RootPath
            attr_reader :value

            def initialize(value)
              @value = value
            end

            def to_pathname
              Pathname.new(value)
            end
          end
        end

        after do
          Object.send(:remove_const, :RootPath)
        end

        let(:root) { RootPath.new('..') }

        it 'expand it to the real path' do
          @configuration.root root
          @configuration.root.must_equal Pathname.new(root.value).realpath
        end
      end
    end

    describe "when a value isn't given" do
      before do
        @configuration.root '.'
      end

      it 'returns the value' do
        @configuration.root.must_equal Pathname.new('.').realpath
      end
    end
  end
end
