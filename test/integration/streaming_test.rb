require 'test_helper'
require 'rack/test'
require 'fixtures/streaming/application'

describe 'Streaming' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('streaming')
    @app = StreamingApp::Application.new
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

  it 'successfully gets the full content' do
    get '/', {}, { 'HTTP_VERSION' => 'HTTP/1.1' }

    response.headers.wont_include 'Content-Length'
    response.headers['Transfer-Encoding'].must_equal 'chunked'
    response.body.must_equal "3\r\none\r\n3\r\ntwo\r\n5\r\nthree\r\n0\r\n\r\n"
  end
end
