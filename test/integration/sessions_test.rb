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

    response.body.must_equal ''
  end

  it 'allows to set session' do
    post '/set_session', { name: 'Lotus' }

    response.body.must_equal 'Session created for: Lotus'
  end

  it 'preserves session between requests' do
    post '/set_session', { name: 'Lotus' }
    get '/get_session', nil, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }

    response.body.must_equal 'Lotus'
  end

  it 'allows to clear session' do
    post '/set_session', { name: 'Lotus' }
    delete '/clear_session', nil, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }

    response.body.must_equal 'Session cleared for: Lotus'

    get '/get_session', nil, { 'HTTP_COOKIE' => response.headers['Set-Cookie'] }

    response.body.must_equal ''
  end
end
