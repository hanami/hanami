# frozen_string_literal: true

RSpec.describe "Container auto-injection (aka \"Deps\") mixin", :app_integration do
  # rubocop:disable Metrics/MethodLength
  def with_app
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/some_service.rb", <<~'RUBY'
        module TestApp
          class SomeService
          end
        end
      RUBY

      write "app/some_operation.rb", <<~'RUBY'
        module TestApp
          class SomeOperation
            include Deps["some_service"]
          end
        end
      RUBY

      yield
    end
  end
  # rubocop:enable Metrics/MethodLength

  specify "Dependencies are auto-injected in a booted app" do
    with_app do
      require "hanami/boot"

      op = TestApp::App["some_operation"]
      expect(op.some_service).to be_a TestApp::SomeService
    end
  end

  specify "Dependencies are lazily resolved and auto-injected in an unbooted app" do
    with_app do
      require "hanami/prepare"

      op = TestApp::App["some_operation"]
      expect(op.some_service).to be_a TestApp::SomeService
    end
  end
end
