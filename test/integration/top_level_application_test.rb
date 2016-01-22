require 'test_helper'
require 'rack/test'
require 'fixtures/information_tech/application'

describe 'A top level Hanami application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('information_tech')
    @app = InformationTech::Application.new
  end

  after do
    Dir.chdir @current_dir
    @current_dir = nil

    _reset_controller_setup
    _reset_view_setup
  end

  def _reset_controller_setup
    Object.send(:remove_const, :Action)
    Object.send(:remove_const, :Controller)
  end

  def _reset_view_setup
    Object.send(:remove_const, :Layout)
    Object.send(:remove_const, :View)
    Object.send(:remove_const, :Presenter)
  end

  def app
    @app
  end

  def response
    last_response
  end

  it 'returns a successful response for a resource'
  # it 'returns a successful response for a resource' do
  #   get '/hardware'

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Information Technology</title>)
  #   response.body.must_match %(<h1>Hardware</h1>)
  # end

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

  it "handles redirects from routes"
  # it "handles redirects from routes" do
  #   get '/legacy'
  #   follow_redirect!

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Information Technology</title>)
  #   response.body.must_match %(<h1>Hardware</h1>)
  # end

  it "handles redirects from actions"
  # it "handles redirects from actions" do
  #   get '/action_legacy'
  #   follow_redirect!

  #   response.status.must_equal 200
  #   response.body.must_match %(<title>Information Technology</title>)
  #   response.body.must_match %(<h1>Hardware</h1>)
  # end

  it "handles thrown statuses from actions" do
    get '/protected'

    response.status.must_equal 401
    response.body.must_match %(<title>Unauthorized</title>)
    response.body.must_match %(<h1>Unauthorized</h1>)
  end
end
