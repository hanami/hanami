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
end
