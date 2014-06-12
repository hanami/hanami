require 'test_helper'
require 'fixtures/collaboration/application'

describe 'A full stack Lotus application' do
  before do
    @application = Rack::MockRequest.new(Collaboration::Application.new)
  end

  it 'returns a successful response for the root path' do
    response = @application.get('/')

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "doesn't try to render responses that aren't coming from an action" do
    response = @application.get('/favicon.ico')
    response.status.must_equal 200
  end

  it "serves static files" do
    response = @application.get('/stylesheets/application.css')
    response.status.must_equal 200

    response = @application.get('/javascripts/application.js')
    response.status.must_equal 200

    response = @application.get('/images/application.jpg')
    response.status.must_equal 200

    response = @application.get('/fonts/cabin-medium.woff')
    response.status.must_equal 200

    response = @application.get('/stylesheets/not-found.css')
    response.status.must_equal 404
  end

  it "renders a custom page for not found resources" do
    response = @application.get('/unknown')

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h1>Not Found</h1>)
  end

  it "renders a custom page for server side errors" do
    response = @application.get('/error')

    response.status.must_equal 500
    response.body.must_match %(<title>Internal Server Error</title>)
    response.body.must_match %(<h1>Internal Server Error</h1>)
  end
end
