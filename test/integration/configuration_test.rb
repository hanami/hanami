require 'test_helper'
require 'rack/test'
require 'fixtures/configurable/application'

describe 'Configurable application' do
  include Rack::Test::Methods

  before do
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('configurable')
    @app = Configurable::Application.new
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

  describe "when it doesn't handle exceptions" do
    it 'let it to be raised' do
      -> { get '/error' }.must_raise(ArgumentError)
    end
  end
end
