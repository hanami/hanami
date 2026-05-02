# frozen_string_literal: true

RSpec.describe "Container / Memoize components", :app_integration do
  describe "Default memoization (all components memoized by default)" do
    it "memoizes all auto-registered components in the app" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/my_component.rb", <<~RUBY
          module TestApp
            class MyComponent
            end
          end
        RUBY

        require "hanami/prepare"

        expect(TestApp::App["my_component"]).to be TestApp::App["my_component"]
      end
    end

    it "memoizes all auto-registered components in slices" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/admin/my_component.rb", <<~RUBY
          module Admin
            class MyComponent
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Admin::Slice["my_component"]).to be Admin::Slice["my_component"]
      end
    end
  end

  describe "Per-file opt-out via magic comment" do
    it "does not memoize a component with a # memoize: false magic comment" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/memoized_component.rb", <<~RUBY
          module TestApp
            class MemoizedComponent
            end
          end
        RUBY

        write "app/not_memoized_component.rb", <<~RUBY
          # memoize: false

          module TestApp
            class NotMemoizedComponent
            end
          end
        RUBY

        require "hanami/prepare"

        expect(TestApp::App["memoized_component"]).to be TestApp::App["memoized_component"]
        expect(TestApp::App["not_memoized_component"]).not_to be TestApp::App["not_memoized_component"]
      end
    end
  end

  describe "Opting out via no_memoize with an array of key prefixes" do
    it "does not memoize components matching the given key prefixes" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.no_memoize = ["workers", "jobs"]
            end
          end
        RUBY

        write "app/services/greeter.rb", <<~RUBY
          module TestApp
            module Services
              class Greeter
              end
            end
          end
        RUBY

        write "app/workers/mailer.rb", <<~RUBY
          module TestApp
            module Workers
              class Mailer
              end
            end
          end
        RUBY

        write "app/jobs/import.rb", <<~RUBY
          module TestApp
            module Jobs
              class Import
              end
            end
          end
        RUBY

        require "hanami/prepare"

        expect(TestApp::App["services.greeter"]).to be TestApp::App["services.greeter"]
        expect(TestApp::App["workers.mailer"]).not_to be TestApp::App["workers.mailer"]
        expect(TestApp::App["jobs.import"]).not_to be TestApp::App["jobs.import"]
      end
    end
  end

  describe "Opting out via no_memoize with a proc" do
    it "does not memoize components for which the proc returns true" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.no_memoize = ->(component) {
                component.key.start_with?("workers")
              }
            end
          end
        RUBY

        write "app/services/greeter.rb", <<~RUBY
          module TestApp
            module Services
              class Greeter
              end
            end
          end
        RUBY

        write "app/workers/mailer.rb", <<~RUBY
          module TestApp
            module Workers
              class Mailer
              end
            end
          end
        RUBY

        require "hanami/prepare"

        expect(TestApp::App["services.greeter"]).to be TestApp::App["services.greeter"]
        expect(TestApp::App["workers.mailer"]).not_to be TestApp::App["workers.mailer"]
      end
    end
  end

  describe "Slice config inheritance" do
    it "slices inherit the app's no_memoize config" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.no_memoize = ["workers"]
            end
          end
        RUBY

        write "slices/admin/services/greeter.rb", <<~RUBY
          module Admin
            module Services
              class Greeter
              end
            end
          end
        RUBY

        write "slices/admin/workers/mailer.rb", <<~RUBY
          module Admin
            module Workers
              class Mailer
              end
            end
          end
        RUBY

        require "hanami/prepare"

        expect(Admin::Slice["services.greeter"]).to be Admin::Slice["services.greeter"]
        expect(Admin::Slice["workers.mailer"]).not_to be Admin::Slice["workers.mailer"]
      end
    end

    it "slices can override the app's no_memoize config" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~RUBY
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.no_memoize = ["workers"]
            end
          end
        RUBY

        write "config/slices/admin.rb", <<~RUBY
          module Admin
            class Slice < Hanami::Slice
              config.no_memoize = ["jobs"]
            end
          end
        RUBY

        write "slices/admin/workers/mailer.rb", <<~RUBY
          module Admin
            module Workers
              class Mailer
              end
            end
          end
        RUBY

        write "slices/admin/jobs/import.rb", <<~RUBY
          module Admin
            module Jobs
              class Import
              end
            end
          end
        RUBY

        require "hanami/prepare"

        # Slice uses its own no_memoize config, not the app's
        expect(Admin::Slice["workers.mailer"]).to be Admin::Slice["workers.mailer"]
        expect(Admin::Slice["jobs.import"]).not_to be Admin::Slice["jobs.import"]
      end
    end
  end
end
