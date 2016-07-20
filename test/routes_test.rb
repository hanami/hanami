require 'test_helper'

describe Hanami::Routes do
  before do
    @scheme   = 'https'
    @host     = 'hanamirb.org'
    @port     = 443
    @original = Hanami::Router.new(scheme: @scheme, host: @host, port: @port) do
      get '/', as: :root
    end

    @routes = Hanami::Routes.new(@original)
  end

  describe '#path' do
    it 'returns a path for the given name' do
      @routes.path(:root).must_equal '/'
    end

    it 'raises an error when the path cannot be found' do
      -> { @routes.path(:unknown) }.must_raise Hanami::Routing::InvalidRouteException
    end

    it 'returns safe string' do
      @routes.path(:root).must_be_kind_of Hanami::Utils::Escape::SafeString
    end
  end

  describe '#url' do
    it 'returns a url for the given name' do
      @routes.url(:root).must_equal "#{ @scheme }://#{ @host }/"
    end

    it 'raises an error when the url cannot be found' do
      -> { @routes.url(:unknown) }.must_raise Hanami::Routing::InvalidRouteException
    end

    it 'returns safe string' do
      @routes.url(:root).must_be_kind_of Hanami::Utils::Escape::SafeString
    end
  end

  describe '#recognize' do
    it 'recognizes a route from a Rack env' do
      env   = Rack::MockRequest.env_for('/')
      route = @routes.recognize(env)

      route.must_be :routable?

      route.path.must_equal '/'
      route.verb.must_equal 'GET'
      route.params.must_equal({})
    end

    it 'does not recognizes a route from wrong Rack env' do
      env   = Rack::MockRequest.env_for('/foo')
      route = @routes.recognize(env)

      route.wont_be :routable?
    end
  end

  describe 'dynamic finders' do
    describe 'for relative URLs' do
      it 'recognizes named route' do
        @routes.root_path.must_equal '/'
      end

      it "raises an error if an unknown path is invoked" do
        -> { @routes.unknown_path }.must_raise Hanami::Routing::InvalidRouteException
      end
    end

    describe 'for absolute URLs' do
      it 'recognizes named route' do
        @routes.root_url.must_equal "#{ @scheme }://#{ @host }/"
      end

      it "raises an error if an unknown url is invoked" do
        -> { @routes.unknown_url }.must_raise Hanami::Routing::InvalidRouteException
      end
    end

    it 'raises an error for unknown methods' do
      -> { @routes.foo }.must_raise NoMethodError
    end
  end
end
