RSpec.describe "handle exceptions", type: :integration do
  it "doesn't handle exceptions in development mode" do
    with_project do
      generate_action

      server do
        get '/books/1'

        expect(last_response.status).to eq(500)
      end
    end
  end

  it "doesn't handle exceptions in test mode" do
    with_project do
      generate_action

      RSpec::Support::Env['HANAMI_ENV'] = 'test'

      server do
        get '/books/1'

        expect(last_response.status).to eq(500)
      end
    end
  end

  context "when handles exceptions in production mode" do
    it "it returns the expected status" do
      with_project do
        generate_action
        setup_production_env

        server do
          get '/books/1'

          expect(last_response.status).to eq(400)
        end
      end
    end

    context "and an exception is raised from a template" do
      it "it returns a 500 and it renders a custom template if it exists" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= raise ArgumentError.new("oh nooooo") %>
          EOF

          write "apps/web/templates/500.html.erb", <<~EOF
            This is a custom template for 500 error
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to eq("This is a custom template for 500 error\n")
          end
        end
      end

      it "it returns a 500 and it renders the default template if custom template doesn't exist" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= raise ArgumentError.new("oh nooooo") %>
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("<h2>500 - Internal Server Error</h2>")
          end
        end
      end

      it "it returns a 500 and renders backtrace error if an exception is raised from 500 custom template" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= raise ArgumentError.new("oh nooooo") %>
          EOF

          write "apps/web/templates/500.html.erb", <<~EOF
            <%= raise ArgumentError.new("Error from custom template") %>
            This is a custom template for 500 error
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to_not include("This is a custom template for 500 error")
            expect(last_response.body).to include("<h1>Boot Error</h1><p>Something went wrong while loading")
          end
        end
      end
    end

    context "and an exception is raised from a view" do
      it "it returns a 500 and it renders a custom template if it exists" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/views/books/show.rb", <<~EOF
            module Web::Views::Books
              class Show
                include Web::View

                def header
                  raise ArgumentError.new("oh nooooo")
                end
              end
            end
          EOF

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= header %>
          EOF

          write "apps/web/templates/500.html.erb", <<~EOF
            This is a custom template for 500 error
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to eq("This is a custom template for 500 error\n")
          end
        end
      end

      it "it returns a 500 and it renders the default template if custom template doesn't exist" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/views/books/show.rb", <<~EOF
            module Web::Views::Books
              class Show
                include Web::View

                def header
                  raise ArgumentError.new("oh nooooo")
                end
              end
            end
          EOF

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= header %>
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to include("<h2>500 - Internal Server Error</h2>")
          end
        end
      end

      it "it returns a 500 and renders backtrace error if an exception is raised from 500 custom template" do
        with_project do
          generate "action web books#show --url=/books/:id"

          rewrite "apps/web/views/books/show.rb", <<~EOF
            module Web::Views::Books
              class Show
                include Web::View

                def header
                  raise ArgumentError.new("oh nooooo")
                end
              end
            end
          EOF

          rewrite "apps/web/templates/books/show.html.erb", <<~EOF
            <%= header %>
          EOF

          write "apps/web/templates/500.html.erb", <<~EOF
            <%= raise ArgumentError.new("Error from custom template") %>
            This is a custom template for 500 error
          EOF

          setup_production_env

          server do
            get '/books/1'

            expect(last_response.status).to eq(500)
            expect(last_response.body).to_not include("This is a custom template for 500 error")
            expect(last_response.body).to include("<h1>Boot Error</h1><p>Something went wrong while loading")
          end
        end
      end
    end
  end

  private

  def generate_action # rubocop:disable Metrics/MethodLength
    generate "action web books#show --url=/books/:id"

    rewrite "apps/web/controllers/books/show.rb", <<-EOF
module Web::Controllers::Books
  class Show
    include Web::Action
    handle_exception ArgumentError => 400

    def call(params)
      raise ArgumentError.new("oh nooooo")
    end
  end
end
EOF
  end

  def setup_production_env
    RSpec::Support::Env['HANAMI_ENV']   = 'production'
    RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"
    RSpec::Support::Env['SMTP_HOST']    = 'localhost'
    RSpec::Support::Env['SMTP_PORT']    = '25'
  end
end
