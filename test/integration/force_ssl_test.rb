require 'test_helper'
require 'rack/test'

describe 'ForceSslApp' do
  include Rack::Test::Methods

  before do
    @application = ForceSslApp::Application.new
  end

  def app
    @application
  end

  def response
    last_response
  end

  it 'get verb return 301, new location and empty body' do
    get '/'

    response.body.must_equal ''
    response.status.must_equal 301
    response.headers['Location'].must_equal 'https://localhost:2300/'
  end

  %w{post put patch delete options}.each do |verb|
    it "#{verb} verb return 307, new location and empty body" do
      public_send verb, '/'

      response.body.must_equal ''
      response.status.must_equal 307
      response.headers['Location'].must_equal 'https://localhost:2300/'
    end
  end
end