require 'test_helper'
require 'rack/test'
require 'fixtures/body_parsers/application'

describe 'Sessions' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('body_parsers')
    @app = BodyParsersApp::Application.new
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

  it 'is successfully parsing a JSON body' do
    post '/json_parser', %({"success": "ok"}),  { 'CONTENT_TYPE' => 'application/json' }

    response.body.must_equal 'ok'
  end

  it 'is successfully parsing a XML body' do
    patch '/xml_parser', %(<success>ok</success>), { "CONTENT_TYPE" => "application/xml" }

    response.body.must_equal 'ok'
  end

  it 'is successfully parsing a XML aliased mime' do
    patch '/xml_parser', %(<success>ok</success>), { 'CONTENT_TYPE' => 'text/xml' }

    response.body.must_equal 'ok'
  end

end
