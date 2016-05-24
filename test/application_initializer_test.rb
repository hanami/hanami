require 'test_helper'
require_relative './fixtures/coffee_shop/config/environment'

describe Hanami::Application do
  describe 'initializers' do
    describe 'when the project is application architecture' do
      before do
        CoffeeShop::Container.new
      end

      describe 'given app/config/initializers exists' do
        it 'loads all the initializers in HANAMI_ROOT/config/initializers only' do
          assert_equal defined?(LongBlackRecipe), 'constant'
          assert_equal defined?(ShortBlackRecipe), 'constant'
          refute_equal defined?(MochaRecipe), 'constant'
        end
      end
    end
  end
end
