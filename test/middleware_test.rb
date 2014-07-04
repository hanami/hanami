require 'test_helper'
require 'lotus/middleware'

Lotus::Middleware.class_eval { attr_reader :stack }

describe Lotus::Middleware do
  before do
    module MockApp
      class Application < Lotus::Application; end
    end
  end

  let(:configuration) { MockApp::Application.configuration }
  let(:middleware)    { configuration.middleware }

  it 'contains only Rack::Static by default' do
    middleware.stack.must_equal [
      [
        Rack::Static,
        [{ urls: configuration.assets.entries, root: configuration.assets }],
        nil
      ]
    ]
  end

  it 'does not include Rack::Static if configuration.assets is set to false' do
    configuration.assets false
    middleware.stack.any? { |m| m.first == Rack::Static }.must_equal false
  end

  describe '#use' do
    it 'inserts a middleware into the stack' do
      middleware.use Rack::ETag
      middleware.stack.must_include [Rack::ETag, [], nil]
      MockApp::Application.new.middleware.stack.must_include [Rack::ETag, [], nil]
    end
  end

  describe '#load' do
    it 'loads the middleware into a Rack::Builder' do
      middleware.use Rack::ETag
      middleware.load!(MockApp::Application.new)
      builder = middleware.instance_variable_get(:@builder)

      builder.instance_variable_get(:@use).size.must_equal 2
    end
  end

  after do
    MockApp.send(:remove_const, :Application)
    Object.send(:remove_const, :MockApp)
  end
end
