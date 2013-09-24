require 'test_helper'
require 'fixtures/blog/application'
require 'fixtures/magazine/application'

describe 'A Lotus application' do
  isolate_me!

  describe 'with a standard layout' do
    before do
      @blog = Rack::MockRequest.new(Blog::Application.new)
    end

    it 'returns a successful response for the root path' do
      response = @blog.get('/')

      response.status.must_equal 200
      response.body.must_match %(<title>Blog: Posts</title>)
      response.body.must_match %(<h1>Posts</h1>)
    end

    it 'returns a server side error when an exeception is raised' do
      response = @blog.get('/raise')

      response.status.must_equal 500
      response.body.must_match %(<title>Internal Server Error</title>)
      response.body.must_match %(<h1>Internal Server Error</h1>)
    end

    it 'returns a not found response for unknown path' do
      response = @blog.get('/unknown')

      response.status.must_equal 404
      response.body.must_match %(<title>Not Found</title>)
      response.body.must_match %(<h1>Not Found</h1>)
    end

    it 'returns an image from public directory' do
      response = @blog.get('/favicon.ico')

      response.status.must_equal 200
    end
  end

  describe 'with a Rails layout' do
    before do
      @magazine = Rack::MockRequest.new(Magazine::Application.new)
    end

    it 'returns a successful response for the root path' do
      response = @magazine.get('/')

      response.status.must_equal 200
      response.body.must_match %(<title>Magazine: Articles</title>)
      response.body.must_match %(<h1>Articles</h1>)
    end
  end
end

#
# app/
#   articles/
#     templates/
#       _form.html.erb
#       index.html.erb
#       new.html.erb
#       edit.html.erb
#     views/
#       index.rb         # Articles::Views::Index
#       show.rb          # Articles::Views::Show
#       new.rb
#       create.rb
#       edit.rb
#     controller.rb      # Articles::Controller, Articles::Controller::Index
#     article.rb         # Article, Articles::Model
#     repository.rb      # Articles::Repository
#
#
# VS
#
#
# app/
#   controllers/
#     articles_controller.rb    # ArticlesController, ArticlesController::Index
#   models/
#     article.rb                # Article
#   repositories/
#     article_repository.rb     # ArticleRepository
#   templates/
#     articles/
#       _form.html.erb
#       index.html.erb
#       new.html.erb
#       edit.html.erb
#   views/
#     articles/
#       index.rb                # Articles::Views::Index
#       show.rb
#       new.rb
#       create.rb
#       edit.rb
