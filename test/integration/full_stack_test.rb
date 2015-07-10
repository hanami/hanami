require 'test_helper'
require 'rack/test'
require 'fixtures/collaboration/apps/web/application'

describe 'A full stack Lotus application' do
  include Rack::Test::Methods

  before do
    ENV['LOTUS_ENV'] = 'development'
    @current_dir = Dir.pwd
    Dir.chdir FIXTURES_ROOT.join('collaboration/apps/web')
    @app = Collaboration::Application.new
  end

  after do
    ENV['LOTUS_ENV'] = 'test'
    Dir.chdir @current_dir
    @current_dir = nil
  end

  def app
    @app
  end

  def response
    last_response
  end

  it 'returns a successful response for the root path' do
    get '/'

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "doesn't try to render responses that aren't coming from an action" do
    get '/favicon.ico'

    response.status.must_equal 200
  end

  it "serves static files" do
    get '/stylesheets/application.css'
    response.status.must_equal 200
    response.body.wont_be_empty

    get '/javascripts/application.js'
    response.status.must_equal 200
    response.body.wont_be_empty

    get '/images/application.jpg'
    response.status.must_equal 200
    response.body.wont_be_empty

    get '/fonts/cabin-medium.woff'
    response.status.must_equal 200
    response.body.wont_be_empty

    get '/stylesheets/not-found.css'
    response.status.must_equal 404
    response.body.wont_be_empty
  end

  it 'serves static files in relative path' do
    get '/lotus.js'
    response.status.must_equal 200
    response.body.wont_be_empty
  end

  it "when user provided a custom template, it renders a custom page" do
    request '/custom_error', 'HTTP_ACCEPT' => 'text/html'

    response.status.must_equal 418

    response.body.must_match %(<title>I&apos;m a teapot</title>)
    response.body.must_match %(<h1>I&apos;m a teapot (418)</h1>)
  end

  it "when html, it renders a custom page for not found resources" do
    request '/unknown', 'HTTP_ACCEPT' => 'text/html'

    response.status.must_equal 404

    response.body.must_match %(<title>Not Found</title>)
    response.body.must_match %(<h1>Not Found</h1>)
  end

  it "when non html, it only returns the status code and message" do
    request '/unknown', 'HTTP_ACCEPT' => 'application/json'

    response.status.must_equal 404
    response.body.must_equal 'Not Found'
  end

  it "when html, it renders a custom page for server side errors" do
    get '/error'

    response.status.must_equal 500
    response.body.must_match %(<title>Internal Server Error</title>)
    response.body.must_match %(<h1>Internal Server Error</h1>)
  end

  it "when non html, it only returns the error status code and message" do
    request '/error', 'HTTP_ACCEPT' => 'application/json'

    response.status.must_equal 500
    response.body.must_equal 'Internal Server Error'
  end

  it "Doesn't render if the body was already set by the action" do
    get '/body'

    response.status.must_equal 200
    response.body.must_equal 'Set by action'
  end

  it "Renders the body from the custom rendering policy" do
    get '/presenter'

    response.status.must_equal 200
    response.body.must_equal 'Set by presenter'
  end

  it "handles redirects from routes" do
    get '/legacy'

    response.status.must_equal 301
    response.body.must_be_empty

    follow_redirect!

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "handles redirects from actions" do
    get '/action_legacy'
    follow_redirect!

    response.status.must_equal 200
    response.body.must_match %(<title>Collaboration</title>)
    response.body.must_match %(<h1>Welcome</h1>)
  end

  it "handles thrown statuses from actions" do
    get '/protected'

    response.status.must_equal 401
    response.body.must_match %(<title>Unauthorized</title>)
    response.body.must_match %(<h1>Unauthorized</h1>)
  end

  describe 'RESTful CRUD' do
    before do
      @book = ::Book.new(name: 'The path to success')
      @book = BookRepository.persist(@book)
    end

    after do
      BookRepository.clear
    end

    it 'handles index action' do
      get '/books'

      response.status.must_equal 200
      response.body.must_include 'There are 1 books'
    end

    it 'handles show action' do
      get "/books/#{@book.id}"

      response.status.must_equal 200

      response.body.must_include "<p id=\"book_id\">#{@book.id}</p>"
      response.body.must_include '<p id="book_name">The path to success</p>'
    end

    it 'handles edit action' do
      get "/books/#{@book.id}/edit"

      response.status.must_equal 200

      response.body.must_include %(<form action="/books/#{ @book.id }" method="POST" accept-charset="utf-8" id="book-form">)
      response.body.must_include %(<input type="hidden" name="_method" value="PATCH">)
      response.body.must_include %(<input type="hidden" name="_csrf_token" value="t0k3n">)
      response.body.must_include %(<input type="text" name="book[name]" id="book-name" value="The path to success" placeholder="Name">)
    end

    it 'handles new action' do
      get "/books/new"

      response.status.must_equal 200

      response.body.must_include %(<form action="/books" method="POST" accept-charset="utf-8" id="book-form">)
      response.body.must_include %(<input type="hidden" name="_csrf_token" value="t0k3n">)
      response.body.must_include %(<input type="text" name="book[name]" id="book-name" value="" placeholder="Name">)
    end

    it 'handles update action' do
      patch "/books/#{@book.id}", book: {name: 'The path to enlightenment'}, '_csrf_token' => 't0k3n'

      response.status.must_equal 302
      response.body.must_equal "Found"

      follow_redirect!

      response.status.must_equal 200
      response.body.must_include "<p id=\"book_id\">#{@book.id}</p>"
      response.body.must_include '<p id="book_name">The path to enlightenment</p>'
    end

    it 'handles create action' do
      post "/books", book: {name: 'The art of Zen'}, '_csrf_token' => 't0k3n'

      response.status.must_equal 302
      response.body.must_equal "Found"

      follow_redirect!

      response.status.must_equal 200
      response.body.must_include '<p id="book_name">The art of Zen</p>'
    end

    it 'handles destroy action' do
      delete "/books/#{@book.id}", '_csrf_token' => 't0k3n'

      response.status.must_equal 302
      response.body.must_equal "Found"

      follow_redirect!

      response.status.must_equal 200
      response.body.must_include 'There are 0 books'
    end
  end

  describe "CSRF Protection" do
    it "handles create action" do
      post "/authors", name: "L", _csrf_token: 'invalid'

      response.status.must_equal 500
      response.body.must_match "Internal Server Error"
    end

    it "handles update action" do
      patch "/authors/15", name: "MG", _csrf_token: 'invalid'

      response.status.must_equal 500
      response.body.must_match "Internal Server Error"
    end

    it "handles destroy action" do
      delete "/authors/99", _csrf_token: 'invalid'

      response.status.must_equal 500
      response.body.must_match "Internal Server Error"
    end
  end

  it 'test route helpers in actions' do
    get '/redirected_routes'

    response.status.must_equal 302
    response.headers['Location'].must_equal '/action_legacy'
  end
end

