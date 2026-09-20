# frozen_string_literal: true

RSpec.describe "Container / Providers in the class body", :app_integration do
  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  specify "a provider can be registered in the app class body" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            register_provider :greeting do
              start { register("greeting", "hello") }
            end
          end
        end
      RUBY

      require "hanami/prepare"

      Hanami.app.start(:greeting)

      expect(Hanami.app["greeting"]).to eq "hello"
    end
  end

  specify "a provider can be registered in a slice class body" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/admin/config/slice.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            register_provider :greeting do
              start { register("greeting", "hello from admin") }
            end
          end
        end
      RUBY

      require "hanami/prepare"

      Admin::Slice.start(:greeting)

      expect(Admin::Slice["greeting"]).to eq "hello from admin"
    end
  end

  specify "a first-party provider can be configured in the app class body" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            configure_provider :db do
              config.gateway(:default) do |gw|
                gw.database_url = "sqlite::memory"
              end
            end
          end
        end
      RUBY

      write "config/db/.keep", ""

      require "hanami/prepare"

      Hanami.app.prepare :db

      expect(Hanami.app["db.gateway"].connection.uri).to eq "sqlite::memory"
    end
  end

  specify "a first-party provider can be configured in a slice class body" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/admin/config/slice.rb", <<~RUBY
        module Admin
          class Slice < Hanami::Slice
            configure_provider :db do
              config.gateway(:default) do |gw|
                gw.database_url = "sqlite::memory"
              end
            end
          end
        end
      RUBY

      write "slices/admin/config/db/.keep", ""

      require "hanami/prepare"

      Admin::Slice.prepare :db

      expect(Admin::Slice["db.gateway"].connection.uri).to eq "sqlite::memory"
    end
  end
end
