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

  # This test is skipped because we won't support "modularized" architecture anymore.
  # See https://github.com/hanami/utils/pull/152
  it 'returns a successful response for a resource'
  # it 'returns a successful response for a resource' do
  #   get '/catalog'

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Furnitures</title>)
  #   response.body.must_match %(<h1>Catalog</h1>)
  # end

  it "renders a custom page for not found resources" do
    get '/unknown'

    response.status.must_equal 404

    response.body.must_match %(<title>404 - Not Found</title>)
    response.body.must_match %(<h2>404 - Not Found</h2>)
  end

  it "renders a custom page for server side errors" do
    get '/error'

    response.status.must_equal 500
    response.body.must_match %(<title>500 - Internal Server Error</title>)
    response.body.must_match %(<h2>500 - Internal Server Error</h2>)
  end

  # This test is skipped because we won't support "modularized" architecture anymore.
  # See https://github.com/hanami/utils/pull/152
  it "handles redirects from routes"
  # it "handles redirects from routes" do
  #   get '/legacy'
  #   follow_redirect!

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Furnitures</title>)
  #   response.body.must_match %(<h1>Catalog</h1>)
  # end

  # This test is skipped because we won't support "modularized" architecture anymore.
  # See https://github.com/hanami/utils/pull/152
  it "handles redirects from actions"
  # it "handles redirects from actions" do
  #   get '/action_legacy'
  #   follow_redirect!

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Furnitures</title>)
  #   response.body.must_match %(<h1>Catalog</h1>)
  # end

  it "handles thrown statuses from actions" do
    get '/protected'

    response.status.must_equal 401
    response.body.must_match %(<title>401 - Unauthorized</title>)
    response.body.must_match %(<h2>401 - Unauthorized</h2>)
  end
end
