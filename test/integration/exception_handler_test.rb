require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/apps/web/application'

describe 'A full stack Lotus application' do
  include Rack::Test::Methods

  before do
    ENV['LOTUS_ENV'] = 'development'
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('collaboration/apps/web')
    @app = Collaboration::Application.new

    @app.configuration.on_exception do |exception, error|
      [500, {}, "Catched exception: #{exception.message}"]
    end
  end

  after do
    ENV['LOTUS_ENV'] = 'test'
    Dir.chdir @current_dir
    @current_dir = nil
  end

  def app
    @app
  end

  def response
    last_response
  end

  it 'returns custom view exception handler message' do
    get '/exceptions/view'

    response.status.must_equal 500
    response.body.must_match %(Catched exception: View exception)
  end

  it 'returns custom template exception handler message' do
    get '/exceptions/template'

    response.status.must_equal 500
    response.body.must_match %(Catched exception: divided by 0)
  end
end

