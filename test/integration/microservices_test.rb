require 'test_helper'
require 'rack/test'
require 'fixtures/microservices/apps/frontend/application'
require 'fixtures/microservices/apps/backend/application'

describe 'A modulized Lotus application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('microservices')

    @app = Lotus::Router.new do
      mount Backend::Application.new,  at: '/backend'
      mount Frontend::Application.new, at: '/'
    end
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

  it 'returns a successful response for a frontend resource' do
    get '/sessions/new'

    response.status.must_equal 200
    response.body.must_match %(<title>Frontend</title>)
    response.body.must_match %(<h1>Sessions</h1>)
  end

  it 'returns a successful response for a backend resource' do
    get '/backend/sessions/new'

    response.status.must_equal 200
    response.body.must_match %(<title>Backend</title>)
    response.body.must_match %(<h1>Sessions</h1>)
  end

  it "doesn't try to render responses that aren't coming from a frontend action" do
    get '/favicon.ico'

    response.status.must_equal 200
  end

  it "doesn't try to render responses that aren't coming from a frontend action" do
    get '/backend/favicon.ico'

    response.status.must_equal 200
  end

  it "serves static files from the frontend" do
    get '/stylesheets/application.css'
    response.status.must_equal 200

    get '/javascripts/application.js'
    response.status.must_equal 200

    get '/images/application.jpg'
    response.status.must_equal 200

    get '/fonts/cabin-medium.woff'
    response.status.must_equal 200

    get '/stylesheets/not-found.css'
    response.status.must_equal 404
  end

  it "serves static files from the backend" do
    get '/backend/stylesheets/application.css'
    response.status.must_equal 200

    get '/backend/javascripts/application.js'
    response.status.must_equal 200

    get '/backend/images/application.jpg'
    response.status.must_equal 200

    get '/backend/fonts/cabin-medium.woff'
    response.status.must_equal 200

    get '/backend/stylesheets/not-found.css'
    response.status.must_equal 404
  end

  it "renders a custom page for frontend not found resources" do
    get '/unknown'

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h1>Not Found</h1>)
  end

  it "renders a custom page for backend not found resources" do
    get '/backend/unknown'

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h1>Not Found</h1>)
  end
end
