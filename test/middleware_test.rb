require 'test_helper'
require 'hanami/middleware'

describe Hanami::Middleware do
  before do
    Dir.chdir($pwd)
    config = config_blk

    MockMiddlewareClass = Class.new
    MockMiddleware      = Object.new
    MockApp             = Module.new

    MockApp::Application = Class.new(Hanami::Application) do
      configure(&config)
    end
  end

  after do
    [:MockMiddlewareClass, :MockMiddleware, :MockApp].each do |klass|
      Object.__send__(:remove_const, klass)
    end
  end

  let(:application)   { MockApp::Application.new }
  let(:configuration) { application.configuration }
  let(:middleware)    { configuration.middleware }
  let(:config_blk) do
    proc do
      root 'test/fixtures/collaboration/apps/web'
    end
  end

  it 'appends new added middleware' do
    middleware.use MockMiddleware
    middleware.stack.last.must_equal [MockMiddleware, [], nil]
  end

  describe "with container architecture" do
    before do
      setup_container_app
    end

    it 'does not contain Rack::MethodOverride by default' do
      middleware.stack.wont_include [Rack::MethodOverride, [], nil]
    end
  end

  describe "with app architecture" do
    before do
      setup_app_app
    end

    it 'contains Rack::MethodOverride for non-container applications' do
      middleware.stack.must_include [Rack::MethodOverride, [], nil]
    end
  end

  def setup_container_app
    File.open('.hanamirc', 'w') { |file| file << "architecture=container"}
  end

  def setup_app_app
    File.open('.hanamirc', 'w') { |file| file << "architecture=app"}
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

    describe 'with other middleware' do
      let(:config_blk) do
        proc do
          middleware.use MockMiddlewareClass
          sessions :cookie
        end
      end

      it 'prepends sessions' do
        sessions_position   = middleware.stack.index(["Rack::Session::Cookie", [{:domain=>nil, :secure=>false}], nil]).to_i
        middleware_position = middleware.stack.index([MockMiddlewareClass, [], nil])

        assert sessions_position < middleware_position,
          "Expected sessions middleware to be prepended"
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
