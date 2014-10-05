require 'test_helper'

describe Lotus::Loader do
  describe '#load!' do
    describe 'frameworks' do
      before do
        @application = CoffeeShop::Application.new
      end

      it 'generates per application frameworks' do
        assert defined?(CoffeeShop::Controller), 'expected CoffeeShop::Controller'
        assert defined?(CoffeeShop::Action),     'expected CoffeeShop::Action'
        assert defined?(CoffeeShop::View),       'expected CoffeeShop::View'
      end

      it 'generates per application classes' do
        assert defined?(CoffeeShop::Routes), 'expected CoffeeShop::Routes'
      end

      it 'configures controller to use custom action module' do
        CoffeeShop::Controller.configuration.action_module.must_equal(CoffeeShop::Action)
      end

      it 'configures controller to use default format' do
        CoffeeShop::Controller.configuration.default_format.must_equal(:html)
      end

      it 'generates controllers namespace' do
        assert defined?(CoffeeShop::Controllers), 'expected CoffeeShop::Controllers'
      end

      it 'generates views namespace' do
        assert defined?(CoffeeShop::Views), 'expected CoffeeShop::Views'
      end

      it 'assigns root to CoffeeShop::View' do
        CoffeeShop::View.configuration.root.must_equal @application.configuration.root.join('app/templates')
      end

      it 'assigns layout to CoffeeShop::View' do
        CoffeeShop::View.configuration.layout.must_equal Lotus::View::Rendering::NullLayout
      end
    end

    describe 'application' do
      before do
        @application = CoffeeShop::Application.new
      end

      describe 'routing' do
        it 'assigns routes' do
          expected = Lotus::Router.new(&@application.configuration.routes)
          @application.routes.path(:root).must_equal expected.path(:root)
        end

        it 'assigns custom endpoint resolver' do
          resolver = @application.routes.instance_variable_get(:@router).instance_variable_get(:@resolver)
          resolver.instance_variable_get(:@namespace).must_equal CoffeeShop
        end

        it 'assigns custom default app' do
          default_app = @application.routes.instance_variable_get(:@router).instance_variable_get(:@default_app)
          default_app.must_be_kind_of(Lotus::Routing::Default)
        end

        it 'assigns scheme, host and port configuration' do
          routes = @application.routes
          routes.url(:root).must_equal 'https://lotus-coffeeshop.org:2300/'
        end
      end

      describe 'middleware' do
        it 'preloads the middleware' do
          @application.middleware.must_be_kind_of(Lotus::Middleware)
        end
      end
    end

    describe 'toplevel' do
      require 'fixtures/toplevel'
      before do
        @application = TopLevelApplication.new
      end

      it 'generates per application frameworks' do
        assert defined?(TopLevelApplication::Controller), 'expected TopLevelApplication::Controller'
        assert defined?(TopLevelApplication::Action),     'expected TopLevelApplication::Action'
        assert defined?(TopLevelApplication::View),       'expected TopLevelApplication::View'
      end
    end

    # describe 'finalization' do
    #   it 'freeze CoffeeShop::View' do
    #     CoffeeShop::View.configuration.root.must_be :frozen?
    #   end
    # end
  end
end
