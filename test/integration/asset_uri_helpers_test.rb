require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/apps/web/application'

describe 'Collaboration::Application::View include AssetUriHelpers' do
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

  describe 'Lotus::View' do
    it 'is able to access asset_path/_url in the view-object and template' do
      get "/use-uri-helpers"

      response.status.must_equal 200

      response.body.must_include "template:&#x2F;assets&#x2F;application.jpg"
      response.body.must_include "template:http:&#x2F;&#x2F;localhost:2300&#x2F;assets&#x2F;application.jpg"
      response.body.must_include "view:&#x2F;assets&#x2F;application.jpg"
      response.body.must_include "view:http:&#x2F;&#x2F;localhost:2300&#x2F;assets&#x2F;application.jpg"
    end
  end
end
