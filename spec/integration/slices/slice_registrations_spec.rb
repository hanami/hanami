# frozen_string_literal: true

RSpec.describe "Slice Registrations", :app_integration do
  matcher :have_key do |name, value|
    match do |slice|
      slice.resolve(name) == value
    end
  end

  specify "Registrations are loaded" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/registrations/foo.rb", <<~RUBY
        TestApp::App.register("foo") { "bar" }
      RUBY

      require "hanami/prepare"

      expect(Hanami.app).to have_key(:foo, "bar")
    end
  end

  specify "Slices load their own registrations" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/slices/main.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
          end
        end
      RUBY

      write "config/slices/admin.rb", <<~RUBY
        module Main
          class Slice < Hanami::Slice
          end
        end
      RUBY

      write "config/registrations/foo.rb", <<~RUBY
        TestApp::App.register("foo") { "bar" }
      RUBY

      write "slices/admin/config/registrations/bar.rb", <<~RUBY
        Admin::Slice.register("bar") { "baz" }
      RUBY

      write "slices/main/config/registrations/baz.rb", <<~RUBY
        Main::Slice.register("baz") { "quux" }
      RUBY

      require "hanami/prepare"

      admin_slice = Hanami.app.slices[:admin]
      main_slice  = Hanami.app.slices[:main]

      aggregate_failures do
        expect(Hanami.app).to have_key(:foo, "bar")
        expect(admin_slice).to have_key(:bar, "baz")
        expect(main_slice).to have_key(:baz, "quux")
      end
    end
  end
end
