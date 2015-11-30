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
end

