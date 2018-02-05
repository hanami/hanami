RSpec.describe "CSRF protection", type: :integration do
  it "protects POST endpoints from invalid token" do
    with_project do
      generate "action web books#create --url=/books --method=POST"
      replace "apps/web/application.rb", "# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']", "sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']"

      server do
        post '/books', title: 'TDD', _csrf_token: 'invalid'

        expect(last_response.status).to eq(500)
      end
    end
  end

  it "protects PATCH endpoints from invalid token" do
    with_project do
      generate "action web books#update --url=/books/:id --method=PATCH"
      replace "apps/web/application.rb", "# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']", "sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']"

      server do
        patch '/books/1', title: 'Foo', _csrf_token: 'invalid'

        expect(last_response.status).to eq(500)
      end
    end
  end

  it "protects DELETE endpoints from invalid token" do
    with_project do
      generate "action web books#destroy --url=/books/:id --method=DELETE"
      replace "apps/web/application.rb", "# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']", "sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']"

      server do
        delete '/books/1', _csrf_token: 'invalid'

        expect(last_response.status).to eq(500)
      end
    end
  end
end
