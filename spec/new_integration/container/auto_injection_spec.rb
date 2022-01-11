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

      write "slices/admin/lib/slice_service.rb", <<~RUBY
        module Admin
          class SliceService
          end
        end
      RUBY

      write "slices/admin/lib/test_op.rb", <<~RUBY
        module Admin
          class TestOp
            include Deps["slice_service"]
          end
        end
      RUBY

      yield
    end
  end
  # rubocop:enable Metrics/MethodLength

  specify "Dependencies are auto-injected in a booted application" do
    with_application do
      require "hanami/setup"
      Hanami.boot

      op = Admin::Slice["test_op"]
      expect(op.slice_service).to be_an Admin::SliceService
    end
  end

  specify "Dependencies are lazily resolved and auto-injected in an unbooted application" do
    with_application do
      require "hanami/init"

      op = Admin::Slice["test_op"]
      expect(op.slice_service).to be_an Admin::SliceService
    end
  end
end
