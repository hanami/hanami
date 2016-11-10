RSpec.describe "handle exceptions", type: :cli do
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

  it "handles exceptions in production mode" do
    with_project do
      generate_action

      RSpec::Support::Env['HANAMI_ENV']   = 'production'
      RSpec::Support::Env['DATABASE_URL'] = "sqlite://#{Pathname.new('db').join('bookshelf.sqlite')}"

      server do
        get '/books/1'

        expect(last_response.status).to eq(400)
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
end
