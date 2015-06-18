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

  describe 'with HTTP scheme' do
    it 'redirects to the same resource that uses SSL' do
      get '/'

      response.status.must_equal              301
      response.body.must_equal                ''
      response.headers['Location'].must_equal "https://#{ ENV_LOCALHOST }:2300/"
    end

    %w{post put patch delete options}.each do |verb|
      it "redirects to the same resource that uses SSL, and forces the same method (#{ verb })" do
        public_send verb, '/'

        response.status.must_equal              307
        response.body.must_equal                ''
        response.headers['Location'].must_equal "https://#{ ENV_LOCALHOST }:2300/"
      end
    end
  end

  describe 'with HTTPS scheme' do
    it 'returns the resource' do
      get "https://#{ ENV_LOCALHOST }:2300/"

      response.status.must_equal 200
      response.body.must_equal   'this is the body'

      response.headers.key?('Location').must_equal false
      response.headers['Strict-Transport-Security'].must_equal 'max-age=31536000'
    end

    %w{post put patch delete options}.each do |verb|
      it "redirects to the same resource that uses SSL, and forces the same method (#{ verb })" do
        public_send verb, "https://#{ ENV_LOCALHOST }:2300/"

        response.status.must_equal 200
        response.body.must_equal   'this is the body'

        response.headers.key?('Location').must_equal false
        response.headers['Strict-Transport-Security'].must_equal 'max-age=31536000'
      end
    end
  end
end
