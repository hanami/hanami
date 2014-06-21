require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/application'

describe 'A full stack Lotus application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('collaboration')
    @app = Collaboration::Application.new
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
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "doesn't try to render responses that aren't coming from an action" do
    get '/favicon.ico'

    response.status.must_equal 200
  end

  it "serves static files" do
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

  it "renders a custom page for not found resources" do
    get '/unknown'

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h1>Not Found</h1>)
  end

  it "renders a custom page for server side errors" do
    get '/error'

    response.status.must_equal 500
    response.body.must_match %(<title>Internal Server Error</title>)
    response.body.must_match %(<h1>Internal Server Error</h1>)
  end

  it "handles redirects from routes" do
    get '/legacy'
    follow_redirect!

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "handles redirects from actions" do
    get '/action_legacy'
    follow_redirect!

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "handles thrown statuses from actions" do
    get '/protected'

    response.status.must_equal 401
    response.body.must_match %(<title>Unauthorized</title>)
    response.body.must_match %(<h1>Unauthorized</h1>)
  end
end
