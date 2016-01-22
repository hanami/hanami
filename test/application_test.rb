require 'test_helper'

describe Hanami::Application do
  before do
    @application = CoffeeShop::Application.new
  end

  it 'instantiate new configuration object when inherited' do
    coffee_shop_app  = CoffeeShop::Application.new
    reviews_app = Reviews::Application.new

    coffee_shop_app.configuration.wont_equal reviews_app.configuration
  end

  describe '.configure' do
    it 'yields the given block and returns a configuration' do
      configuration = CoffeeShop::Application.configuration

      configuration.must_be_kind_of Hanami::Configuration
      configuration.root.must_equal Pathname.new(__dir__).join('../tmp/coffee_shop')
    end
  end

  describe 'subclasses' do
    before do
      Hanami::Application.applications.clear

      module Foo
        class Application < Hanami::Application
          def self.load!(application = self)
            @@loaded = true
          end

          def self.loaded?
            @@loaded
          end

          configure { }
        end
      end
    end

    after do
      Object.__send__(:remove_const, :Foo)
    end

    it 'register subclasses' do
      Hanami::Application.applications.must_include(Foo::Application)
    end

    it 'preloads registered subclasses' do
      Hanami::Application.preload!
      Foo::Application.must_be :loaded?
    end
  end

  describe '#configuration' do
    it 'returns class configuration' do
      @application.configuration.must_equal @application.class.configuration
    end
  end

  describe '#initialize' do
    it 'loads the frameworks and the application' do
      @application.routes.must_be_kind_of(Hanami::Router)
    end
  end

  describe '#name' do
    it 'returns the class name' do
      @application.name.must_equal @application.class.name
    end
  end
end
