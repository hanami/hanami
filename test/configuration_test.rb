require 'test_helper'
require 'lotus/router'

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

  describe '#load_paths' do
    before do
      @configuration.root '.'
    end

    describe 'by default' do
      it "it's equal to root" do
        @configuration.load_paths.must_include @configuration.root.join('app')
      end
    end

    it 'allows to add other paths' do
      @configuration.load_paths << '..'
      @configuration.load_paths.must_include '..'
    end
  end

  describe '#routes' do
    describe 'when a block is given' do
      let(:routes) { Proc.new { get '/', to: ->{}, as: :root } }

      it 'sets the routes' do
        @configuration.routes(&routes)

        router = Lotus::Router.new(&@configuration.routes)
        router.path(:root).must_equal '/'
      end
    end

    describe 'when a relative path is given' do
      describe "and it's valid" do
        let(:path) { __dir__ + '/fixtures/routes' }

        it 'sets the routes' do
          @configuration.routes(path)

          router = Lotus::Router.new(&@configuration.routes)
          router.path(:root).must_equal '/'
        end
      end

      describe "and it's unknown" do
        let(:path) { __dir__ + '/fixtures/unknown' }

        it 'raises an error' do
          @configuration.routes(path)

          -> {
            Lotus::Router.new(&@configuration.routes)
          }.must_raise ArgumentError
        end
      end
    end
  end

  # describe '#mapping' do
  #   describe 'when a block is given' do
  #     let(:mapping) { Proc.new { collection :customers do; end } }

  #     it 'sets the database mapping' do
  #       @configuration.mapping(&mapping)

  #       mapper = Lotus::Model::Mapper.new(&@configuration.mapping)
  #       mapper.collection(:customers).must_be_kind_of Lotus::Model::Mapping::Collection
  #     end
  #   end

  #   describe 'when a relative path is given' do
  #     describe "and it's valid" do
  #       let(:path) { __dir__ + '/fixtures/mapping' }

  #       it 'sets the routes' do
  #         @configuration.mapping(path)

  #         mapper = Lotus::Model::Mapper.new(&@configuration.mapping)
  #         mapper.collection(:customers).must_be_kind_of Lotus::Model::Mapping::Collection
  #       end
  #     end

  #     describe "and it's unknown" do
  #       let(:path) { __dir__ + '/fixtures/unknown' }

  #       it 'raises an error' do
  #         @configuration.mapping(path)

  #         -> {
  #           Lotus::Model::Mapper.new(&@configuration.mapping)
  #         }.must_raise ArgumentError
  #       end
  #     end
  #   end
  # end

  describe '#layout' do
    describe "when not previously set" do
      it 'defaults to nil' do
        @configuration.layout.must_be_nil
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.layout(:other)
        @configuration.layout.must_equal :other
      end
    end

    describe "when called with nil" do
      it 'sets the value' do
        @configuration.layout(nil)
        @configuration.layout.must_be_nil
      end
    end
  end

  describe '#scheme' do
    describe "when not previously set" do
      it 'defaults to a specific value' do
        @configuration.scheme.must_equal 'http://'
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.scheme(scheme = 'https://')
        @configuration.scheme.must_equal scheme
      end
    end
  end

  describe '#host' do
    describe "when not previously set" do
      it 'defaults to a specific value' do
        @configuration.host.must_equal 'localhost'
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.host(host = 'lotusrb.org')
        @configuration.host.must_equal host
      end
    end
  end

  describe '#port' do
    describe "when not previously set" do
      describe "and scheme is set on 'http://'" do
        it 'defaults to a specific value' do
          @configuration.port.must_equal '80'
        end
      end

      describe "and scheme is set on 'https://'" do
        before do
          @configuration.scheme 'https://'
        end

        it 'defaults to a specific value' do
          @configuration.port.must_equal '443'
        end
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.port(port = '8080')
        @configuration.port.must_equal port
      end
    end
  end

  describe '#controller_pattern' do
    describe "when not previously set" do
      it 'defaults to a specific value' do
        @configuration.controller_pattern.must_equal 'Controllers::%{controller}::%{action}'
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.controller_pattern(pattern = '%{controller}Controller::%{action}')
        @configuration.controller_pattern.must_equal pattern
      end
    end
  end
end
