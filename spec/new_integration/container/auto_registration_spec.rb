# frozen_string_literal: true

RSpec.describe "Container auto-registration", :application_integration do
  specify "Booted application auto-registers files in application and slice lib/ directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/test_op.rb", <<~RUBY
        module TestApp
          class TestOp
          end
        end
      RUBY

      write "slices/admin/lib/admin/test_op.rb", <<~RUBY
        module Admin
          class TestOp
          end
        end
      RUBY

      require "hanami/setup"
      Hanami.boot web: false

      expect(TestApp::Application["test_op"]).to be_a TestApp::TestOp
      expect(Admin::Slice["test_op"]).to be_an Admin::TestOp
    end
  end

  it "Unbooted application resolves components lazily from the lib/ directories" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "lib/test_app/test_op.rb", <<~RUBY
        module TestApp
          class TestOp
          end
        end
      RUBY

      write "slices/admin/lib/admin/test_op.rb", <<~RUBY
        module Admin
          class TestOp
          end
        end
      RUBY

      require "hanami/init"

      expect(TestApp::Application.keys).not_to include("test_op")
      expect(TestApp::Application["test_op"]).to be_a TestApp::TestOp
      expect(TestApp::Application.keys).to include("test_op")

      expect(Admin::Slice.keys).not_to include("test_op")
      expect(Admin::Slice["test_op"]).to be_an Admin::TestOp
      expect(Admin::Slice.keys).to include("test_op")
    end
  end
end
