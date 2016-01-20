require 'test_helper'
require 'rack/test'

describe Hanami::Container do
  include Rack::Test::Methods

  def app
    @container
  end

  def response
    last_response
  end

  describe 'force_ssl activated' do
    before do
      Hanami::Container.configure do
        mount Backend::App,                   at: '/backend'
        mount ContainerForceSsl::Application, at: '/'
      end

      @container = Hanami::Container.new
    end

    it "doesn't force SSL if app doesn't has force_ssl turned on" do
      get '/backend'

      response.status.must_equal 200
      response.body.must_equal  'home'
    end

    it 'https request return Strict-Transport-Security header' do
      get 'https://localhost:2300'

      response.status.must_equal 200
      response.body.must_equal  'hello ContainerForceSsl'

      response.headers.key?('Location').must_equal false
      response.headers['Strict-Transport-Security'].must_equal 'max-age=31536000'
    end
  end

  describe 'force_ssl desactivated' do
    before do
      Hanami::Container.configure do
        mount ContainerNoForceSsl::Application, at: '/'
      end

      @container = Hanami::Container.new
    end

    it "https request doesn't return Strict-Transport-Security header" do
      get 'https://localhost:2300'

      response.status.must_equal 200
      response.body.must_equal   'hello ContainerNoForceSsl'

      response.headers.key?('Location').must_equal                  false
      response.headers.key?('Strict-Transport-Security').must_equal false
    end
  end
end
