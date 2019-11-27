# frozen_string_literal: true

RSpec.describe "Container auto-injection (aka \"Deps\") mixin", :application_integration do
  def with_application
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/shared_service.rb", <<~RUBY
        module TestApp
          class SharedService
          end
        end
      RUBY

      write "slices/admin/lib/admin/slice_service.rb", <<~RUBY
        module Admin
          class SliceService
          end
        end
      RUBY

      write "slices/admin/lib/admin/test_op.rb", <<~RUBY
        module Admin
          class TestOp
            include Deps[
              "slice_service",
              app_service: "application.shared_service",
            ]
          end
        end
      RUBY

      yield
    end
  end

  specify "Dependencies are auto-injected in a booted application" do
    with_application do
      require "hanami/setup"
      Hanami.boot web: false

      op = Admin::Slice["test_op"]
      expect(op.slice_service).to be_an Admin::SliceService
      expect(op.app_service).to be_a TestApp::SharedService
    end
  end

  specify "Dependencies are lazily resolved and auto-injected in an unbooted application" do
    with_application do
      require "hanami/init"

      op = Admin::Slice["test_op"]
      expect(op.slice_service).to be_an Admin::SliceService
      expect(op.app_service).to be_a TestApp::SharedService
    end
  end
end
