require 'test_helper'
require 'rack/test'
require 'fixtures/microservices/apps/frontend/application'
require 'fixtures/microservices/apps/backend/application'

describe 'Hanami microservices applications' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('microservices')

    @app = Hanami::Router.new do
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
