require 'test_helper'
require 'lotus/middleware'

describe Lotus::Middleware do
  before do
    config = config_blk
    MockApp = Module.new
    MockApp::Application = Class.new(Lotus::Application) do
      configure &config
    end
  end

  after do
    Object.send(:remove_const, :MockApp)
  end

  let(:application)   { MockApp::Application.new }
  let(:configuration) { application.configuration }
  let(:middleware)    { configuration.middleware }
  let(:config_blk)    { proc {} }

  it 'contains only Rack::Static by default' do
    middleware.stack.must_equal [[Rack::Static, [{ urls: [], root: configuration.assets.to_s }], nil]]
  end

  describe "when it's configured with disabled assets" do
    let(:config_blk) { proc { assets :disabled } }

    it 'does not include Rack::Static' do
      middleware.stack.flatten.wont_include(Rack::Static)
    end
  end

  describe "when it's configured with sessions" do
    let(:config_blk) { proc { sessions :cookie } }

    it 'includes sessions middleware' do
      middleware.stack.must_include ["Rack::Session::Cookie", [{ domain: configuration.host, secure: false }], nil]
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
