require 'test_helper'
require 'rack/test'
require 'fixtures/middleware_stack/application'

describe Hanami::Container do
  include Rack::Test::Methods

  before do
    Hanami::Container.configure do
      mount MiddlewareStack::Application, at: '/middleware'
    end

    @container = Hanami::Container.new
    MiddlewareStack::Application.load!
  end

  def app
    @container
  end

  def response
    last_response
  end

  it 'applies the MethodOverride middleware to map POST to PATCH given correct header' do
    post '/middleware/', {}, { 'HTTP_X_HTTP_METHOD_OVERRIDE' => 'PATCH' }

    response.status.must_equal 200
    response.body.must_equal %(Update successful)
  end
end
