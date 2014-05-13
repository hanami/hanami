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
        assert defined?(CoffeeShop::View),       'expected CoffeeShop::View'
      end

      it 'assigns handled exceptions to CoffeeShop::Controller' do
        CoffeeShop::Controller.handled_exceptions.must_equal({ Lotus::Model::EntityNotFound => 404 })
      end

      it 'assigns root to CoffeeShop::View' do
        CoffeeShop::View.root.must_equal @application.configuration.root
      end

      it 'assigns layout to CoffeeShop::View' do
        CoffeeShop::View.layout.must_equal CoffeeShop::ApplicationLayout
      end

      it 'assigns configuration to CoffeeShop::View'
    end

    describe 'application' do
      it 'assigns routes' do
        expected = Lotus::Router.new(&@application.configuration.routes)
        @application.routes.path(:root).must_equal expected.path(:root)
      end

      it 'assigns mapping' do
        expected = Lotus::Model::Mapper.new(&@application.configuration.mapping)
        @application.mapping.collection(:customers).name.must_equal expected.collection(:customers).name
      end
    end

    describe 'finalization' do
      it 'freeze CoffeeShop::View' do
        CoffeeShop::View.root.must_be :frozen?
      end
    end
  end
end
