require 'test_helper'
require 'rack/test'
require 'fixtures/custom_error_templates/application'

describe 'A custom error templates Lotus application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('custom_error_templates')
    @app = CustomErrorTemplates::Application.new
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

  it "renders a custom page for not found resources" do
    get '/error'

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h2>Not Found</h2>)
  end

  it "renders a custom page for unprocessable entity resources" do
    get '/unprocessable_entity'

    response.status.must_equal 422

    response.body.must_match %(<title>Unprocessable Entity</title>)
    response.body.must_match %(<h2>Unprocessable Entity</h2>)
  end

  it "renders a custom page for internal server error resources" do
    get '/internal_server_error'

    response.status.must_equal 500

    response.body.must_match %(<title>Internal Server Error</title>)
    response.body.must_match %(<h2>Internal Server Error</h2>)
  end
end
