require 'test_helper'

describe Lotus::Application do
  before do
    @application = CoffeeShop::Application.new
  end

  describe '.configure' do
    it 'yields the given block and returns a configuration' do
      configuration = CoffeeShop::Application.configuration

      configuration.must_be_kind_of Lotus::Configuration
      configuration.root.must_equal Pathname.new(__dir__).join('../tmp/coffee_shop')
    end
  end

  describe '#configuration' do
    it 'returns class configuration' do
      @application.configuration.must_equal @application.class.configuration
    end
  end

  describe '#initialize' do
    it 'loads the frameworks and the application' do
      @application.routes.must_be_kind_of(Lotus::Router)
    end
  end
end
