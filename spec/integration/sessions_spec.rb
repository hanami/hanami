RSpec.describe "Sessions", type: :cli do
  let(:token) { "abc123" }

  it "is empty by default" do
    with_project do
      prepare

      server do
        get '/session'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("[empty]")
      end
    end
  end

  xit "preserves data across requests" do
    with_project do
      prepare

      server do
        # Create
        post '/session', name: "Luca", _csrf_token: token

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("Session created for: Luca")

        # Read
        get '/session', nil, 'HTTP_COOKIE' => last_response.headers['Set-Cookie']

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("Luca")
      end
    end
  end

  xit "clears the session" do
    with_project do
      prepare

      server do
        # Create
        post '/session', name: "Luca", _csrf_token: token

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("Session created for: Luca")

        # Delete
        delete '/session', { _csrf_token: token }, 'HTTP_COOKIE' => last_response.headers['Set-Cookie']

        expect(last_response.status).to eq(200)
        expect(last_response.body).to   eq("Session cleared for: Luca")
      end
    end
  end

  private

  def prepare
    # Enable sessions
    replace "apps/web/application.rb", "# sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']", "sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']"

    # Make CSRF token protection to always return "token" in order to make testing easier
    replace "apps/web/application.rb", "controller.prepare do", "controller.prepare do\ninclude Module.new {\ndef generate_csrf_token\n'#{token}'\nend\n}"

    generate_actions
  end

  def generate_actions # rubocop:disable Metrics/MethodLength
    generate "action web sessions#create --url=/session --method=POST"
    generate "action web sessions#show --url=/session --method=GET"
    generate "action web sessions#destroy --url=/session --method=DELETE"

    rewrite "apps/web/controllers/sessions/create.rb", <<-EOF
module Web::Controllers::Sessions
  class Create
    include Web::Action

    def call(params)
      session[:name] = params[:name]
      self.body = "Session created for: \#{session[:name]}"
    end
  end
end
EOF

    rewrite "apps/web/controllers/sessions/show.rb", <<-EOF
module Web::Controllers::Sessions
  class Show
    include Web::Action

    def call(params)
      self.body = session[:name] || "[empty]"
    end
  end
end
EOF

    rewrite "apps/web/controllers/sessions/destroy.rb", <<-EOF
module Web::Controllers::Sessions
  class Destroy
    include Web::Action

    def call(params)
      name = session[:name]
      session.clear
      self.body = "Session cleared for: \#{name}"
    end
  end
end
EOF
  end
end
