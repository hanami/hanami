# frozen_string_literal: true

require "rack/test"
require "stringio"

RSpec.describe "Logging / Exception logging", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  let(:logger_stream) { StringIO.new }

  def configure_logger
    Hanami.app.config.logger.stream = logger_stream
  end

  def logs
    @logs ||= (logger_stream.rewind and logger_stream.read)
  end

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            # Disable framework-level error rendering so we can test the raw action behavior
            config.render_errors = false
            config.render_detailed_errors = false
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            root to: "test"
          end
        end
      RUBY

      require "hanami/setup"
      configure_logger

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "unhandled exceptions" do
    def before_prepare
      write "app/actions/test.rb", <<~RUBY
        module TestApp
          module Actions
            class Test < Hanami::Action
              UnhandledError = Class.new(StandardError)

              def handle(request, response)
                raise UnhandledError, "unhandled"
              end
            end
          end
        end
      RUBY
    end

    it "logs a 500 error and full exception details when an exception is raised" do
      # Make the request with a rescue so the raised exception doesn't crash the tests
      begin
        get "/"
      rescue TestApp::Actions::Test::UnhandledError # rubocop:disable Lint/SuppressedException
      end

      expect(logs.lines.length).to be > 10
      expect(logs).to match %r{GET 500 \d+(µs|ms) 127.0.0.1 /}
      expect(logs).to include("unhandled (TestApp::Actions::Test::UnhandledError)")
      expect(logs).to include("app/actions/test.rb:7:in `handle'")
    end

    it "re-raises the exception" do
      expect { get "/" }.to raise_error(TestApp::Actions::Test::UnhandledError)
    end
  end

  describe "errors handled by handle_exception" do
    def before_prepare
      write "app/actions/test.rb", <<~RUBY
        module TestApp
          module Actions
            class Test < Hanami::Action
              NotFoundError = Class.new(StandardError)

              handle_exception NotFoundError => :handle_not_found_error

              def handle(request, response)
                raise NotFoundError
              end

              private

              def handle_not_found_error(request, response, exception)
                halt 404
              end
            end
          end
        end
      RUBY
    end

    it "does not log an error" do
      get "/"

      expect(logs).to match %r{GET 404 \d+(µs|ms) 127.0.0.1 /}
    end
  end
end
