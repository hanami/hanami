require 'test_helper'
require 'rack/test'
require 'fixtures/one_file/application'

describe 'A one file Hanami application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('one_file')
    @app = OneFile::Application.new
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
    response.body.must_equal %(Hello)
  end
end
