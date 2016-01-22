require 'test_helper'
require 'rack/test'
require 'fixtures/furnitures/application'

describe 'A modulized Hanami application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('furnitures')
    @app = Furnitures::Application.new
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

  it 'returns a successful response for a resource' do
    get '/catalog'

    response.status.must_equal 200
    response.body.must_match %(<title>Furnitures</title>)
    response.body.must_match %(<h1>Catalog</h1>)
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
    response.body.must_match %(<title>Furnitures</title>)
    response.body.must_match %(<h1>Catalog</h1>)
  end

  it "handles redirects from actions" do
    get '/action_legacy'
    follow_redirect!

    response.status.must_equal 200
    response.body.must_match %(<title>Furnitures</title>)
    response.body.must_match %(<h1>Catalog</h1>)
  end

  it "handles thrown statuses from actions" do
    get '/protected'

    response.status.must_equal 401
    response.body.must_match %(<title>Unauthorized</title>)
    response.body.must_match %(<h1>Unauthorized</h1>)
  end
end
