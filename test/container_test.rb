require 'test_helper'
require 'rack/mock'

describe Lotus::Container do
  describe '.configure' do
    before do
      @blk = -> { mount RackApp, at: '/rack' }
      Lotus::Container.configure(&@blk)
    end

    it 'allows to define mounted applications with a block' do
      assert Lotus::Container.class_variable_get(:@@configuration) == @blk, "Expected Lotus::Container configuration to equal @blk"
    end

    it 'allows to redefine the configuration' do
      blk = -> { mount RackApp, at: '/rack2' }
      Lotus::Container.configure(&blk)

      assert Lotus::Container.class_variable_get(:@@configuration) == blk, "Expected Lotus::Container configuration to equal blk"
    end
  end

  describe '#initialize' do
    describe 'with defined applications' do
      before do
        Lotus::Container.configure do
          mount RackApp, at: '/rack'
        end
      end

      it 'wraps them in a router' do
        routes = Lotus::Container.new.routes
        routes.must_be_kind_of(Lotus::Router)
      end
    end

    describe 'without configuration' do
      before do
        Lotus::Container.remove_class_variable(:@@configuration) rescue nil
      end

      it 'raises error when initialized' do
        exception = -> { Lotus::Container.new }.must_raise ArgumentError
        exception.message.must_equal "Lotus::Container doesn't have any application mounted."
      end
    end
  end

  describe '#call' do
    before do
      Lotus::Container.configure do
        mount RackApp, at: '/rack'
      end
    end

    it 'forwards calls to inner router' do
      env = Rack::MockRequest.env_for('/rack', {})
      status, headers, body = Lotus::Container.new.call(env)

      status.must_equal  200
      headers.must_equal({})
      body.must_equal ['Hello from RackApp']
    end
  end
end
