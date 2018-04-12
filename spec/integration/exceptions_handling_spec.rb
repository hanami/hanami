RSpec.describe "exceptions handling", type: :integration do
  context "handled exceptions" do
    it "handles exceptions in development mode" do
      with_project do
        generate_action_with_handled_exception

        server do
          get '/books/1'

          expect(last_response.status).to eq(400)
          expect(last_response.body).to include("Bad Request")
        end
      end
    end

    it "doesn't handle exceptions in test mode" do
      with_project do
        generate_action_with_handled_exception

        RSpec::Support::Env['HANAMI_ENV'] = 'test'

        server do
          get '/books/1'

          expect(last_response.status).to eq(400)
          expect(last_response.body).to include("Bad Request")
        end
      end
    end

    it "handles exceptions in production mode" do
      with_project do
        generate_action_with_handled_exception

        RSpec::Support::Env['HANAMI_ENV']   = 'production'
        RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
        RSpec::Support::Env['SMTP_HOST']    = 'localhost'
        RSpec::Support::Env['SMTP_PORT']    = '25'

        server do
          get '/books/1'

          expect(last_response.status).to eq(400)
          expect(last_response.body).to include("Bad Request")
        end
      end
    end

    context "custom template" do
      it "renders when exception is handled with HTTP code" do
        with_project do
          generate_action_with_handled_exception
          generate_error_template(400)

          server do
            get '/books/1'

            expect(last_response.status).to eq(400)
            expect(last_response.body).to include("Sad panda")
            expect(last_response.body).to include("Bad Request")
          end
        end
      end

      it "renders when exception is handled with action method" do
        with_project do
          generate_action_with_handled_exception_via_method
          generate_error_template(400)

          server do
            get '/books/1'

            expect(last_response.status).to eq(400)
            expect(last_response.body).to include("Sad panda")
            expect(last_response.body).to include("Please check your request")
          end
        end
      end
    end
  end

  context "unhandled exceptions" do
    it "shows backtrace in development mode" do
      with_project do
        generate_action_with_unhandled_exception

        server do
          get '/books/1'

          expect(last_response.status).to eq(500)
          expect(last_response.body).to include("ArgumentError at /books/1")
          expect(last_response.body).to include("oh nooooo")
        end
      end
    end

    it "shows backtrace in test mode" do
      with_project do
        generate_action_with_unhandled_exception

        RSpec::Support::Env['HANAMI_ENV'] = 'test'

        server do
          get '/books/1'

          expect(last_response.status).to eq(500)
          expect(last_response.body).to include("ArgumentError: oh nooooo")
        end
      end
    end

    context "production" do
      before do
        RSpec::Support::Env['HANAMI_ENV']   = 'production'
        RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
        RSpec::Support::Env['SMTP_HOST']    = 'localhost'
        RSpec::Support::Env['SMTP_PORT']    = '25'
      end

      it "handles action exceptions" do
        with_project do
          generate_action_with_unhandled_exception

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("Internal Server Error")
          end
        end
      end

      it "handles view exceptions" do
        with_project do
          generate_view_with_unhandled_exception

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("Internal Server Error")
          end
        end
      end

      it "handles template exceptions" do
        with_project do
          generate_template_with_unhandled_exception

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("Internal Server Error")
          end
        end
      end

      it "renders custom template" do
        with_project do
          generate_action_with_unhandled_exception
          generate_error_template(500)

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("Sad panda")
            expect(last_response.body).to include("Internal Server Error")
          end
        end
      end
    end
  end

  private

  def generate_action_with_handled_exception # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"

    rewrite "apps/web/controllers/books/show.rb", <<-EOF
module Web
  module Controllers
    module Books
      class Show < Hanami::Action
        handle_exception ArgumentError => 400

        def call(*)
          raise ArgumentError.new("oh nooooo")
        end
      end
    end
  end
end
EOF
  end

  def generate_action_with_handled_exception_via_method # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"

    rewrite "apps/web/controllers/books/show.rb", <<-EOF
module Web
  module Controllers
    module Books
      class Show < Hanami::Action
        handle_exception ArgumentError => :handle_exceptions

        def call(*)
          raise ArgumentError.new("oh nooooo")
        end

        private

        def handle_exceptions(_, res, _)
          res.status = 400
          res.body   = "Please check your request"
        end
      end
    end
  end
end
EOF
  end

  def generate_action_with_unhandled_exception # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"

    rewrite "apps/web/controllers/books/show.rb", <<-EOF
module Web
  module Controllers
    module Books
      class Show < Hanami::Action
        def call(*)
          raise ArgumentError.new("oh nooooo")
        end
      end
    end
  end
end
EOF
  end

  def generate_view_with_unhandled_exception # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"

    rewrite "apps/web/views/books/show.rb", <<-EOF
module Web::Views::Books
  class Show
    include Web::View

    def title
      foo
    end
  end
end
EOF

    rewrite "apps/web/templates/books/show.html.erb", <<-EOF
<%= title %>
EOF
  end

  def generate_template_with_unhandled_exception # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"
    rewrite "apps/web/templates/books/show.html.erb", <<-EOF
<%= missing %>
EOF
  end

  def generate_error_template(status_code)
    write "apps/web/templates/#{status_code}.html.erb", <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
  </head>
  <body>
    <h1>Sad panda</h1>
    <h2><%= title %></h2>
  </body>
</html>
EOF
  end
end
