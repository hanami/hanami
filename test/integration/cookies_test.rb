require 'test_helper'
require 'rack/test'
require 'fixtures/cookies/application'

describe 'Cookies' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('cookies')
    @app = CookiesApp::Application.new
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

  it 'sucessfully gets cookies' do
    get '/get_cookies', nil, {'HTTP_COOKIE' => 'foo=bar'}

    request.cookies.must_equal({ 'foo' => 'bar' })

    response.body.must_equal('bar')
    response.headers['Set-Cookie'].must_equal('foo=bar; domain=hanamirb.org; path=/another_controller; secure; HttpOnly')
  end

  it 'succesfully sets cookies' do
    get '/set_cookies'

    response.body.must_equal('yummy!')
    response.headers['Set-Cookie'].must_equal('foo=nomnomnom%21; domain=hanamirb.org; path=/another_controller; secure; HttpOnly')
  end

  it 'sucessfully sets cookies with options' do
    next_week = Time.now + 60 * 60 * 24 * 7
    get '/set_cookies_with_options', { expires: next_week }

    response.body.must_equal('with options!')
    response.headers['Set-Cookie'].must_equal("foo=nomnomnom%21; domain=hanamirocks.com; path=/controller; expires=#{next_week.gmtime.rfc2822}; secure; HttpOnly")
  end

  it 'sucessfully deletes cookies' do
    get '/del_cookies', nil, {'HTTP_COOKIE' => 'foo=bar;delete=cookie'}

    request.cookies.must_equal({ 'foo' => 'bar', 'delete' => 'cookie' })

    response.body.must_equal('deleted!')
    response.headers['Set-Cookie'].must_equal("foo=bar; domain=hanamirb.org; path=/another_controller; secure; HttpOnly\ndelete=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000")
  end
end
