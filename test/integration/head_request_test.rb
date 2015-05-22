require 'test_helper'
require 'rack/test'
require 'fixtures/lint/application'

describe 'Sessions' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('lint')

    @app = Rack::Builder.new {
      use Rack::Lint
      run Lint::Application.new
    }
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

  it 'returns empty body for HEAD requests (view)' do
    head '/'

    response.status.must_equal 200
    response.body.must_equal ''
  end

  it 'returns empty body for HEAD requests (with direct body setter)' do
    head '/greet'

    response.status.must_equal 200
    response.body.must_equal ''
  end

  it 'sends file' do
    get '/download'

    response.status.must_equal 200
    response.body.wont_be :empty?
  end

  it 'returns empty body for HEAD requests (with file send)' do
    head '/download'

    response.status.must_equal 200
    response.body.must_equal ''
  end
end
