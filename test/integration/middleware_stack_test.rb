require 'test_helper'
require 'rack/test'
require 'fixtures/middleware_stack/application'

describe 'Middleware stack' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('middleware_stack')
    @app = MiddlewareStack::Application.new
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil
  end

  def app
    @app
  end

  def response
    last_response
  end

  it 'returns a successful response for the root path' do
    get '/'

    response.status.must_equal 200
    response.body.must_equal %(Hello)

    response.headers['ETag'].wont_be_nil
    response.headers['X-Custom'].must_equal  'OK'
    response.headers['X-Runtime'].must_equal '50ms'
  end

  it 'returns a not found response for assets' do
    get '/logo.png'

    response.status.must_equal 404
  end
end
