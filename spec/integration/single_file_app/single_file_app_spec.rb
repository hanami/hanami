# frozen_string_literal: true

require "rack/test"

RSpec.describe "Single-file app", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify do
    with_tmp_directory(Dir.mktmpdir) do
      write "app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL

            register_provider :greeting do
              start { register("greeting", "Hello from a single file") }
            end

            configure_provider :db do
              config.gateway(:default) do |gw|
                gw.database_url = "sqlite::memory"
              end
            end

            register("actions.home") { TestApp::Actions::Home.new }
          end

          module Actions
            class Home < Hanami::Action
              def handle(request, response)
                response.body = TestApp::App["greeting"]
              end
            end
          end

          class Settings < Hanami::Settings
            setting :tagline, default: "One file is all you need"
          end

          class Routes < Hanami::Routes
            root to: "home"
          end
        end
      RUBY

      require File.join(Dir.pwd, "app")

      TestApp::App.boot

      get "/"
      expect(last_response.body).to eq "Hello from a single file"

      expect(TestApp::Actions::Home).to be_configured_for_slice(TestApp::App)
      expect(TestApp::App["settings"].tagline).to eq "One file is all you need"
      expect(TestApp::App["db.gateway"].connection.uri).to eq "sqlite::memory"
    end
  end
end
