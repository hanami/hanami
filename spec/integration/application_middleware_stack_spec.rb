RSpec.describe "Application middleware stack", type: :integration do
  it "mounts Rack middleware" do
    with_project do
      generate "action web home#index --url=/"
      generate_middleware

      # Add apps/web/middleware to the load paths
      replace "apps/web/application.rb", "load_paths << [", "load_paths << ['middleware',"

      # Require Rack::ETag
      unshift "apps/web/application.rb", "require 'rack/etag'"

      # Mount middleware
      replace "apps/web/application.rb", "# middleware.use", "middleware.use 'Web::Middleware::Runtime'\nmiddleware.use 'Web::Middleware::Custom', 'OK'\nmiddleware.use Rack::ETag"

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
    write "apps/web/middleware/runtime.rb", <<-EOF
module Web
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
end
EOF

    write "apps/web/middleware/custom.rb", <<-EOF
module Web
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
end
EOF
  end
end
