require 'test_helper'
require 'lotus/middleware'

describe Lotus::Middleware do
  before do
    Dir.chdir($pwd)
    config = config_blk

    MockMiddleware = Object.new
    MockApp        = Module.new

    MockApp::Application = Class.new(Lotus::Application) do
      configure(&config)
    end
  end

  after do
    [:MockMiddleware, :MockApp].each do |klass|
      Object.__send__(:remove_const, klass)
    end
  end

  let(:application)   { MockApp::Application.new }
  let(:configuration) { application.configuration }
  let(:middleware)    { configuration.middleware }
  let(:config_blk) do
    proc do
      root 'test/fixtures/collaboration/apps/web'
      serve_assets true
    end
  end

  # See https://github.com/lotus/lotus/issues/283
  it 'prepends new added middleware' do
    middleware.use MockMiddleware
    middleware.stack.first.must_equal [MockMiddleware, [], nil]
  end

  it 'contains Rack::MethodOverride by default' do
    middleware.stack.must_include [Rack::MethodOverride, [], nil]
  end

  describe "when it's configured with assets" do
    let(:urls) { configuration.assets.entries.values.flatten }

    it 'contains only Rack::Static by default' do
      middleware.stack.must_include [Rack::Static, [{ urls: urls, root: configuration.root.join('public').to_s }], nil]
    end
  end

  describe "when it's configured with disabled assets" do
    let(:config_blk) { proc { serve_assets false } }

    it 'does not include Rack::Static' do
      middleware.stack.flatten.wont_include(Rack::Static)
    end
  end

  describe "when it's configured with sessions" do
      let(:config_blk) do
        proc do
          sessions :cookie
          host 'localhost'
        end
      end

    it 'domain is nil in sessions middleware' do
      middleware.stack.must_include ['Rack::Session::Cookie', [{ domain: nil, secure: false }], nil]
    end

    describe 'and configured with domain 0.0.0.0' do
      let(:config_blk) do
        proc do
          sessions :cookie
          host '0.0.0.0'
        end
      end

      it 'domain is nil in sessions middleware' do
        middleware.stack.must_include ['Rack::Session::Cookie', [{ domain: nil, secure: false }], nil]
      end
    end

    describe 'and configured with domain foo.com' do
      let(:config_blk) do
        proc do
          sessions :cookie
          host 'foo.com'
        end
      end

      it 'domain is equal to the host in sessions middleware' do
        middleware.stack.must_include ['Rack::Session::Cookie', [{ domain: 'foo.com', secure: false }], nil]
      end
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
