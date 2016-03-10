require 'test_helper'
require_relative './fixtures/coffee_shop/config/environment'
require_relative './fixtures/tea_shop/config/environment'

describe Hanami::Application do
  before do
    Hanami::Application.clear_registered_applications!
  end

  describe 'initializers' do
    describe 'when the project is application architecture' do
      before do
        CoffeeShop::Application.new
      end

      describe 'given app/config/initializers exists' do
        it 'loads all the initializers in HANAMI_ROOT/config/initializers only' do
          assert_equal defined?(LongBlackRecipe), 'constant'
          assert_equal defined?(ShortBlackRecipe), 'constant'
          refute_equal defined?(MochaRecipe), 'constant'
        end
      end
    end

    describe 'when the project is container architecture' do
      before do
        TeaShop::Container.new
      end

      describe 'given apps/<name>/config/initializers exists' do
        it 'loads all the initializers in HANAMI_ROOT/config/initializers only' do
          assert_equal defined?(OolongTea), 'constant'
          refute_equal defined?(BlackTea), 'constant'
          refute_equal defined?(GreenTea), 'constant'
        end
      end
    end
  end
end
