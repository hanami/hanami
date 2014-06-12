require 'test_helper'

describe Lotus::Loader do
  before do
    CoffeeShop::Application.configuration.root.join('app/templates').mkpath

    @application = CoffeeShop::Application.new
    @loader      = Lotus::Loader.new(@application)
  end

  describe '#load!' do
    describe 'frameworks' do
      it 'generates per application frameworks' do
        assert defined?(CoffeeShop::Controller), 'expected CoffeeShop::Controller'
        assert defined?(CoffeeShop::Action),     'expected CoffeeShop::Action'
        assert defined?(CoffeeShop::View),       'expected CoffeeShop::View'
      end

      it 'configures controller to use custom action module' do
        CoffeeShop::Controller.configuration.action_module.must_equal(CoffeeShop::Action)
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
      end

      describe 'middleware' do
        it 'preloads the middleware' do
          @application.middleware.must_be_kind_of(Lotus::Middleware)
        end
      end
    end

    # describe 'finalization' do
    #   it 'freeze CoffeeShop::View' do
    #     CoffeeShop::View.configuration.root.must_be :frozen?
    #   end
    # end
  end
end
