require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/apps/web/application'
require 'fixtures/security_headers/apps/web/application'

describe 'A full stack Lotus application' do
  describe 'with default headers' do
    include Rack::Test::Methods

    before do
      @current_dir = Dir.pwd
      Dir.chdir FIXTURES_ROOT.join('collaboration/apps/web')
      @app = Collaboration::Application.new
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

    it "returns default headers' value" do
      get '/'

      response.headers['X-Frame-Options'].must_equal 'DENY'
      response.headers['Content-Security-Policy'].must_equal "connect-src 'self'; script-src 'self';"
    end
  end

  describe 'overriding default headers' do
    include Rack::Test::Methods

    before do
      @current_dir = Dir.pwd
      Dir.chdir FIXTURES_ROOT.join('security_headers/apps/web')
      @app = SecurityHeaders::Application.new
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

    it "returns overrided headers' value" do
      get '/'

      response.headers['X-Frame-Options'].must_equal 'ALLOW ALL'
      response.headers['Content-Security-Policy'].must_equal "script-src 'self' https://apis.google.com"
    end
  end
end