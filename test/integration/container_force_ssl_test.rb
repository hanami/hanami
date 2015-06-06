require 'test_helper'
require 'rack/test'

describe Lotus::Container do
  include Rack::Test::Methods

  def app
    @container
  end

  def response
    last_response
  end

  describe 'force_ssl activated' do
    before do
      Lotus::Container.configure(force_ssl: true, host: 'lotus.test') do
        mount Backend::App,         at: '/backend'
        mount RackApp,              at: '/rackapp'
        mount ContainerForceSsl::Application, at: '/container_force_ssl'
      end

      @container = Lotus::Container.new
    end

    it 'force ssl in backend app creates redirection' do
      get '/backend/'

      response.status.must_equal 301
      response.headers['Location'].must_equal 'https://lotus.test:443/backend/'
      response.body.must_equal ''
    end

    it 'force ssl in rackapp app creates redirection' do
      get '/rackapp/'

      response.status.must_equal 301
      response.headers['Location'].must_equal 'https://lotus.test:443/rackapp/'
      response.body.must_equal ''
    end

    it 'https request return Strict-Transport-Security header' do
      get 'https://lotus.test/container_force_ssl/'

      response.status.must_equal 200
      response.headers['Location'].must_be_nil
      response.headers['Strict-Transport-Security'].must_equal 'max-age=31536000'
      response.body.must_equal 'hello ContainerForceSsl'
    end
  end

  describe 'force_ssl desactivated' do
    before do
      Lotus::Container.configure do
        mount Backend::App, at: '/backend'
        mount RackApp,      at: '/rackapp'
        mount ContainerNoForceSsl::Application, at: '/container_force_ssl'
      end

      @container = Lotus::Container.new
    end

    it 'force ssl in backend app creates redirection' do
      get '/backend/'

      response.status.must_equal 200
      response.headers['Location'].must_be_nil
      response.body.must_equal 'home'
    end

    it 'force ssl in rackapp app creates redirection' do
      get '/rackapp/'

      response.status.must_equal 200
      response.headers['Location'].must_be_nil
      response.body.must_equal 'Hello from RackApp'
    end

    it "https request doesn't return Strict-Transport-Security header" do
      get 'https://lotus.test/container_force_ssl/'

      response.status.must_equal 200
      response.headers['Location'].must_be_nil
      response.headers['Strict-Transport-Security'].must_be_nil
      response.body.must_equal 'hello ContainerNoForceSsl'
    end
  end
end
