require 'test_helper'
require_relative './fixtures/coffee_shop/config/environment'

describe Hanami::Application do
  before do
    Hanami::Application.clear_registered_applications!
    @application = CoffeeShop::Application.new
  end

  describe '.configuration' do
    it 'yields the given block and returns a configuration' do
      configuration = CoffeeShop::Application.configuration

      configuration.must_be_kind_of Hanami::Configuration
      configuration.root.must_equal Pathname.new(__dir__).join('../test/fixtures/coffee_shop')
    end
  end

  describe '#configuration' do
    it 'returns class configuration' do
      @application.configuration.must_equal @application.class.configuration
    end

    describe 'given 2 instances of same application' do
      before do
        @other_application = CoffeeShop::Application.new
      end

      it 'shares configuration instance' do
        @application.configuration.object_id.must_equal @other_application.configuration.object_id
      end
    end

    describe 'given 2 instances of different application' do
      before do
        @other_application = Reviews::Application.new
      end

      it 'does not share configuration instance' do
        @application.configuration.object_id.wont_equal @other_application.configuration.object_id
      end
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
