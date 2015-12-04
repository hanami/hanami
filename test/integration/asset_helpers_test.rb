require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/apps/web/application'

describe '' do
  include Rack::Test::Methods

  attr_reader :app

  before do
    Dir.chdir FIXTURES_ROOT.join('collaboration/apps/web')

    @app = Collaboration::Application.new
  end

  after do
    Dir.chdir($pwd)
  end

  def response
    last_response
  end

  describe 'image helper' do
    it 'renders an img tag' do
      get "/assets"

      response.status.must_equal 200

      response.body.must_include "<img src=\"/assets/application.jpg\" alt=\"Application\">"
    end
  end

  describe 'video helper' do
    it 'renders a video tag' do
      get "/assets"

      response.status.must_equal 200

      response.body.must_include "<video src=\"/assets/movie.mp4\"></video>"
    end

    it 'renders a video tag with source tags' do
      get "/assets"

      response.status.must_equal 200

      response.body.must_include %(<video>\nYour browser does not support the video tag\n<source src="/assets/movie.mp4" type="video/mp4">\n<source src="/assets/movie.ogg" type="video/ogg">\n</video>)
    end
  end

  describe 'favicon helper' do
    it 'renders a favicon link tag' do
      get "/assets"

      response.status.must_equal 200

      response.body.must_include "<link href=\"/assets/favicon.ico\" rel=\"shortcut icon\" type=\"image/x-icon\">"
    end

    it 'renders a favicon link tag with optional path' do
      get "/assets"

      response.status.must_equal 200

      response.body.must_include "<link href=\"/assets/myfavicon.ico\" rel=\"shortcut icon\" type=\"image/x-icon\">"
    end
  end
end
