# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Serve Static Assets", :app_integration do
  include Rack::Test::Methods
  let(:app) { Hanami.app }
  let(:root) { make_tmp_directory }

  before do
    with_directory(root) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.middleware.use Hanami::Middleware::Assets
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: ->(env) { [200, {}, ["Hello from root"]] }
          end
        end
      RUBY

      write "public/assets/app.js", <<~JS
        console.log("Hello from app.js");
      JS

      require "hanami/boot"
    end
  end

  it "serves static assets" do
    get "/assets/app.js"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to match(/Hello/)
  end

  it "returns 404 for missing asset" do
    get "/assets/missing.js"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to match(/Not Found/i)
  end

  it "doesn't escape from root directory" do
    get "/assets/../../config/app.rb"

    expect(last_response.status).to eq(404)
    expect(last_response.body).to match(/Not Found/i)
  end
end
