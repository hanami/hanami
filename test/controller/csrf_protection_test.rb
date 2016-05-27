require 'test_helper'
require 'rack/mock'

describe Hanami::Action::CSRFProtection do
  describe "when active" do
    before do
      @action = CSRFAction.new
    end

    it "is successful for GET request" do
      env = Rack::MockRequest.env_for('/', {})
      status, _, _ = @action.call(env)

      status.must_equal 200
    end

    it "is successful for HEAD request" do
      env = Rack::MockRequest.env_for('/', method: 'HEAD')
      status, _, _ = @action.call(env)

      status.must_equal 200
    end

    it "is successful if token matches" do
      token = @action.csrf_token
      env   = Rack::MockRequest.env_for('/', method: 'POST', params: { '_csrf_token' => token })
      status, _, _ = @action.call(env)

      status.must_equal 200
    end

    [ 'GET', 'HEAD', 'TRACE', 'OPTIONS' ].each do |verb|
      it "doesn't raise error if token doesn't match (#{ verb })" do
        env = Rack::MockRequest.env_for('/', method: verb, params: { '_csrf_token' => 'nope' })
        status, _, _ = @action.call(env)

        status.must_equal 200
      end
    end

    describe "when HANAMI_ENV is 'test'" do
      before do
        @hanami_env       = ENV['HANAMI_ENV']
        ENV['HANAMI_ENV'] = 'test'

        @action = Class.new do
          include Hanami::Action
          include Hanami::Action::Session
          include Hanami::Action::CSRFProtection

          configuration.handle_exceptions false

          def call(env)
            # ...
          end
        end.new
      end

      after do
        ENV['HANAMI_ENV'] = @hanami_env
      end

      [ 'POST', 'PATCH', 'PUT', 'DELETE' ].each do |verb|
        it "doesn't raises error if token doesn't match (#{ verb })" do
          env = Rack::MockRequest.env_for('/', method: verb, params: { '_csrf_token' => 'nope' })
          status, _, _ = @action.call(env)

          status.must_equal 200
        end
      end
    end

    describe "when HANAMI_ENV isn't 'test'" do
      before do
        @hanami_env       = ENV['HANAMI_ENV']
        @rack_env        = ENV['RACK_ENV']
        ENV['HANAMI_ENV'] = 'development'
        ENV['RACK_ENV']  = 'development'

        @action = Class.new do
          include Hanami::Action
          include Hanami::Action::Session
          include Hanami::Action::CSRFProtection

          configuration.handle_exceptions false

          def call(env)
            # ...
          end
        end.new
      end

      after do
        ENV['HANAMI_ENV'] = @hanami_env
        ENV['RACK_ENV']  = @rack_env
      end

      [ 'POST', 'PATCH', 'PUT', 'DELETE' ].each do |verb|
        it "raises error if token doesn't match (#{ verb })" do
          env = Rack::MockRequest.env_for('/', method: verb, params: { '_csrf_token' => 'nope' })

          -> { @action.call(env) }.must_raise Hanami::Action::InvalidCSRFTokenError
          @action.__send__(:session).must_be :empty? # reset session
        end

        it "raises error if token isn't sent (#{ verb })" do
          env = Rack::MockRequest.env_for('/', method: verb)

          -> { @action.call(env) }.must_raise Hanami::Action::InvalidCSRFTokenError
        end
      end
    end
  end

  describe "with concrete params" do
    before do
      @action = FilteredCSRFAction.new
    end

    it "is successful if token matches" do
      token = @action.csrf_token
      env   = Rack::MockRequest.env_for('/', method: 'POST', params: { '_csrf_token' => token })
      status, _, _ = @action.call(env)

      status.must_equal 200
    end
  end

  describe "when disabled" do
    before do
      @action = DisabledCSRFAction.new
    end

    it "raises error if token isn't sent" do
      env = Rack::MockRequest.env_for('/', method: 'POST')
      status, _, _ = @action.call(env)

      status.must_equal 200
    end
  end
end
