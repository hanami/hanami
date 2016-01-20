require 'test_helper'
require 'rack/test'
require 'fixtures/sessions/application'

describe 'Sessions' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('sessions')
    @app = SessionsApp::Application.new
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

  def request
    last_request
  end

  it 'has empty session by default' do
    get '/get_session'

    response.body.must_equal '[empty]'
  end

  it 'allows to set session' do
    post '/set_session', { name: 'Hanami', _csrf_token: 'app123' }

    response.body.must_equal 'Session created for: Hanami'
  end

  it 'preserves session between requests' do
    post '/set_session', { name: 'Hanami', _csrf_token: 'app123' }
    get '/get_session', nil, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }

    response.body.must_equal 'Hanami'
  end

  it 'allows to clear session' do
    post '/set_session', { name: 'Hanami', _csrf_token: 'app123' }

    delete '/clear_session', { _csrf_token: 'app123'}, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }
    response.body.must_equal 'Session cleared for: Hanami'

    get '/get_session', nil, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }
    response.body.must_equal '[empty]'
  end
end
