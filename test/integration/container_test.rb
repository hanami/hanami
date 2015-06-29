require 'test_helper'
require 'rack/test'

describe Lotus::Container do
  include Rack::Test::Methods

  before do
    Lotus::Container.configure do
      mount Front::Application, at: '/front'
      mount Back::Application,  at: '/back'
    end

    @container = Lotus::Container.new
  end

  def app
    @container
  end

  def response
    last_response
  end

  it 'should reach to endpoints' do
    get '/back/home'
    response.status.must_equal 200
    response.body.must_equal 'hello Back'

    get '/front/home'
    response.status.must_equal 200
    response.body.must_equal 'hello Front'

    get '/back/users'
    response.status.must_equal 200
    response.body.must_equal 'hello from Back users endpoint'
  end

  it 'should print correct routes' do
    matches = [
      'GET, HEAD  /front/home                    Front::Controllers::Home::Show',
      'GET, HEAD  /back/home                     Back::Controllers::Home::Show',
      'GET, HEAD  /back/users                    Back::Controllers::Users::Index'
    ]
    matches.each do |match|
      @container.routes.inspector.to_s.must_match match
    end
  end

  it 'should generate correct urls with route helpers' do
    Front::Routes.path(:home).must_equal '/front/home'
    Back::Routes.path(:home).must_equal '/back/home'
  end
end
