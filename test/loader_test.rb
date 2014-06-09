require 'test_helper'

describe Lotus::Loader do
  before do
    @application = CoffeeShop::Application.new
    @loader      = Lotus::Loader.new(@application)
  end

  describe '#load!' do
    before do
      @loader.load!
    end

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
        CoffeeShop::View.configuration.root.must_equal @application.configuration.root
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
      end

      it 'assigns mapping' do
        expected = Lotus::Model::Mapper.new(&@application.configuration.mapping)
        @application.mapping.collection(:customers).name.must_equal expected.collection(:customers).name
      end
    end

    # describe 'finalization' do
    #   it 'freeze CoffeeShop::View' do
    #     CoffeeShop::View.configuration.root.must_be :frozen?
    #   end
    # end
  end
end
