# frozen_string_literal: true

require "rack/test"

RSpec.describe "Web / Router errors", :app_integration do
  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File.new("/dev/null", "w")
            config.render_errors = true
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            get "/books", to: "books.index", as: :books
            post "/books", to: "books.create"
          end
        end
      RUBY

      require "hanami/prepare"
    end
  end

  let(:router) { Hanami.app.router }

  describe "not found" do
    subject(:error) do
      router.call(Rack::MockRequest.env_for("/missing", method: "GET"))
    rescue Hanami::Router::NotFoundError => exception
      exception
    end

    it "carries the slice that was routing the request" do
      expect(error.slice).to be Hanami.app
    end

    it "makes the slice's routes available" do
      routes = error.slice.router.routes.map { |route| "#{route.http_method} #{route.path}" }

      expect(routes).to include("GET /books", "POST /books")
    end
  end

  describe "not allowed" do
    subject(:error) do
      router.call(Rack::MockRequest.env_for("/books", method: "DELETE"))
    rescue Hanami::Router::NotAllowedError => exception
      exception
    end

    it "carries the slice that was routing the request" do
      expect(error.slice).to be Hanami.app
    end

    it "carries the allowed methods" do
      expect(error.allowed_methods).to include("GET", "POST")
    end
  end
end
