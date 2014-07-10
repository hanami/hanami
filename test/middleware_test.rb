require 'test_helper'
require 'lotus/middleware'

describe Lotus::Middleware do
  before do
    module MockApp
      class Application < Lotus::Application; end
    end
  end

  after do
    Object.send(:remove_const, :MockApp)
  end

  let(:application)   { MockApp::Application.new }
  let(:configuration) { application.configuration }
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

  describe "when it's configured with disabled assets" do
    before do
      configuration.assets :disabled
    end

    it 'does not include Rack::Static' do
      middleware.stack.wont_include(Rack::Static)
    end
  end


  describe '#use' do
    it 'inserts a middleware into the stack' do
      middleware.use Rack::ETag
      middleware.stack.must_include [Rack::ETag, [], nil]
    end

    it 'inserts a middleware into the stack with arguments' do
      middleware.use Rack::ETag, 'max-age=0, private, must-revalidate'
      middleware.stack.must_include [Rack::ETag, ['max-age=0, private, must-revalidate'], nil]
    end

    it 'inserts a middleware into the stack with a block' do
      block = -> { }
      middleware.use Rack::BodyProxy, &block
      middleware.stack.must_include [Rack::BodyProxy, [], block]
    end
  end
end
