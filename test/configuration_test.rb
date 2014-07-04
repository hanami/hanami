require 'test_helper'
require 'lotus/router'

describe Lotus::Configuration do
  before do
    module MockApp
    end

    ENV['RACK_ENV']   = nil
    ENV['LOTUS_ENV']  = nil
    ENV['LOTUS_HOST'] = nil
    ENV['LOTUS_PORT'] = nil

    @namespace     = MockApp
    @configuration = Lotus::Configuration.new
  end

  after do
    Object.send(:remove_const, :MockApp)
  end

  describe '#configure' do
    describe 'when block is given' do
      it 'stores for later evaluation' do
        @configuration.configure do
          root __dir__
        end.load!(@namespace)

        @configuration.root.must_equal Pathname(__dir__).realpath
      end
    end

    describe 'when no block is given' do
      it 'when loaded it will set defaults values' do
        @configuration.root.must_equal Pathname(Dir.pwd).realpath
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

  describe '#namespace' do
    describe "when not previously set" do
      it "returns nil" do
        @configuration.namespace.must_be_nil
      end

      describe "when the configuration is loaded" do
        before do
          @configuration.load!(MockApp)
        end

        it "returns the value" do
          @configuration.namespace.must_equal MockApp
        end
      end
    end

    describe "when previously set" do
      before do
        @configuration.namespace Object
      end

      it 'returns the value' do
        @configuration.namespace.must_equal Object
      end

      describe "when the configuration is loaded" do
        before do
          @configuration.configure do
            namespace Object
          end

          @configuration.load!(MockApp)
        end

        it "returns returns the value set by the configure block" do
          @configuration.namespace.must_equal Object
        end
      end
    end
  end

  describe '#load_paths' do
    before do
      @configuration.root '.'
    end

    describe 'by default' do
      it "is empty" do
        @configuration.load_paths.must_be_empty
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

  describe '#middleware' do
    it 'returns a new instance of Lotus::Middleware' do
      @configuration.middleware.must_be_instance_of Lotus::Middleware
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

  describe '#templates' do
    describe "when not previously set" do
      it "is equal to configuration's root" do
        @configuration.root.wont_be_nil
        @configuration.templates.must_equal @configuration.root
      end
    end

    describe "when set" do
      before do
        @configuration.templates 'app/templates'
      end

      it 'returns the configured value' do
        @configuration.templates.must_equal @configuration.root.join('app/templates')
      end
    end
  end

  describe 'assets' do
    describe "when not previously set" do
      it "is equal to public/ from the root directory" do
        @configuration.assets.to_s.must_equal @configuration.root.join('public').to_s
      end
    end

    describe "when set" do
      before do
        @configuration.assets 'assets'
      end

      it 'returns the configured value' do
        @configuration.assets.to_s.must_equal @configuration.root.join('assets').to_s
      end
    end
  end

  describe '#default_format' do
    describe "when not previously set" do
      it 'returns nil' do
        @configuration.default_format.must_equal :html
      end
    end

    describe "when set" do
      before do
        @configuration.default_format :json
      end

      it 'returns the value' do
        @configuration.default_format.must_equal :json
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      -> { @configuration.default_format(23) }.must_raise TypeError
    end
  end

  describe '#scheme' do
    describe "when not previously set" do
      it 'defaults to a specific value' do
        @configuration.scheme.must_equal 'http'
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.scheme(scheme = 'https')
        @configuration.scheme.must_equal scheme
      end
    end
  end

  describe '#host' do
    before do
      ENV['LOTUS_HOST'] = nil
      ENV['LOTUS_ENV']  = nil
    end

    describe "when not previously set" do
      before do
        @configuration = Lotus::Configuration.new
      end

      it 'defaults to a specific value' do
        @configuration.host.must_equal 'localhost'
      end
    end

    describe "when the env var is set" do
      before do
        ENV['LOTUS_HOST'] = 'lotustest.org'
        @configuration = Lotus::Configuration.new
      end

      it 'returns that value' do
        @configuration.host.must_equal 'lotustest.org'
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
      it 'defaults to 2300' do
        @configuration.port.must_equal 2300
      end
    end

    describe "when the env var is set" do
      before do
        ENV['LOTUS_PORT'] = '2306'
        @configuration = Lotus::Configuration.new
      end

      after do
        ENV['LOTUS_PORT'] = nil
      end

      it 'returns that value' do
        @configuration.port.must_equal 2306
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.port(port = '8080')
        @configuration.port.must_equal port.to_i
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

  describe '#view_pattern' do
    describe "when not previously set" do
      it 'defaults to a specific value' do
        @configuration.view_pattern.must_equal 'Views::%{controller}::%{action}'
      end
    end

    describe "when called with an argument" do
      it 'sets the value' do
        @configuration.view_pattern(pattern = '%{controller}View::%{action}')
        @configuration.view_pattern.must_equal pattern
      end
    end
  end

  describe '#freeze' do
    before do
      @configuration.freeze
    end

    it 'must be frozen' do
      @configuration.must_be :frozen?
    end

    it 'it raises error when try to load!' do
      -> { @configuration.load! 'Bookshelf' }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate root' do
      -> { @configuration.root '..' }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate assets' do
      -> { @configuration.assets 'assets' }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate templates' do
      -> { @configuration.assets 'app/templates' }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the configure block' do
      -> { @configuration.configure(&Proc.new{}) }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the controller_pattern' do
      -> { @configuration.controller_pattern('%{controller}::%{action}') }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the view_pattern' do
      -> { @configuration.view_pattern('%{controller}::%{action}') }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the default_format' do
      -> { @configuration.default_format(:xml) }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the scheme' do
      -> { @configuration.scheme('http') }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the host' do
      -> { @configuration.host('example.org') }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the port' do
      -> { @configuration.port(80) }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the layout' do
      -> { @configuration.layout(:another) }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the load_paths' do
      -> { @configuration.load_paths << 'app/controllers' }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the namespace' do
      -> { @configuration.namespace(Object) }.must_raise RuntimeError
    end

    it 'it raises error when try to mutate the routes' do
      -> { @configuration.routes(&Proc.new{}) }.must_raise RuntimeError
    end
  end
end
