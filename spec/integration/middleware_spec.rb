RSpec.describe "Project middleware", type: :integration do
  it "mounts Rack middleware" do
    with_project do
      generate_middleware

      unshift "config/environment.rb", 'require "rack/etag"'
      unshift "config/environment.rb", 'require_relative "./middleware/runtime"'
      unshift "config/environment.rb", 'require_relative "./middleware/custom"'

      inject_line_after "config/environment.rb", "Hanami.configure", <<-EOL
middleware.use Middleware::Runtime
middleware.use Middleware::Custom, "OK"
middleware.use Rack::ETag
EOL

      generate "action web home#index --url=/"
      rewrite "apps/web/controllers/home/index.rb", <<-EOF
module Web::Controllers::Home
  class Index
    include Web::Action

    def call(params)
      self.body = "OK"
    end
  end
end
EOF

      server do
        get '/'

        expect(last_response.status).to               eq(200)

        expect(last_response.headers["X-Runtime"]).to eq("1ms")
        expect(last_response.headers["X-Custom"]).to  eq("OK")
        expect(last_response.headers["ETag"]).to_not  be_nil
      end
    end
  end

  private

  def generate_middleware # rubocop:disable Metrics/MethodLength
    write "config/middleware/runtime.rb", <<-EOF
module Middleware
  class Runtime
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["X-Runtime"]  = "1ms"

      [status, headers, body]
    end
  end
end
EOF

    write "config/middleware/custom.rb", <<-EOF
module Middleware
  class Custom
    def initialize(app, value)
      @app   = app
      @value = value
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["X-Custom"]   = @value

      [status, headers, body]
    end
  end
end
EOF
  end
end
