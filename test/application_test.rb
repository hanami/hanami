require 'test_helper'

describe Lotus::Application do
  before do
    @application = CoffeeShop::Application.new
  end

  describe '.configure' do
    it 'yields the given block and returns a configuration' do
      configuration = CoffeeShop::Application.configuration

      configuration.must_be_kind_of Lotus::Configuration
      configuration.root.must_equal Pathname.new(__dir__)
    end
  end
end
