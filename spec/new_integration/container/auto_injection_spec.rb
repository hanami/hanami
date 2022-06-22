# frozen_string_literal: true

RSpec.describe "Container auto-injection (aka \"Deps\") mixin", :application_integration do
  # rubocop:disable Metrics/MethodLength
  def with_application
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
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

  specify "Dependencies are auto-injected in a booted application" do
    with_application do
      require "hanami/boot"

      op = TestApp::Application["some_operation"]
      expect(op.some_service).to be_a TestApp::SomeService
    end
  end

  specify "Dependencies are lazily resolved and auto-injected in an unbooted application" do
    with_application do
      require "hanami/prepare"

      op = TestApp::Application["some_operation"]
      expect(op.some_service).to be_a TestApp::SomeService
    end
  end
end
