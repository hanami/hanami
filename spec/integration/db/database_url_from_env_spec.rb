# frozen_string_literal: true

RSpec.describe "DB / Database URL from ENV components", :app_integration do
  subject(:database_urls) {
    Hanami.app.container.providers[:db].source.finalize_config.database_urls
  }

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  def with_app(&blk)
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/relations/.keep", ""

      blk.call
    end
  end

  it "prefers DATABASE_URL when it is given alongside component ENV vars" do
    with_app do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://db/app.sqlite3")
    end
  end

  it "builds the URL from all the component ENV vars" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "postgres"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_PASSWORD"] = "s3cret"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"
      ENV["DATABASE_NAME"] = "app_development"

      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("pg").and_return(true)

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://hanami:s3cret@localhost:5432/app_development"
      )
    end
  end

  it "escapes the user and password" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_USER"] = "user@example.com"
      ENV["DATABASE_PASSWORD"] = "p@ss word"
      ENV["DATABASE_HOST"] = "localhost"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "sqlite://user%40example.com:p%40ss%20word@localhost"
      )
    end
  end

  it "omits the user, password and database name when they are not given" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://localhost:5432")
    end
  end

  it "omits the password when only the user is given" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_HOST"] = "localhost"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://hanami@localhost")
    end
  end

  it "derives the scheme from an aliased adapter name" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "postgresql"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("pg").and_return(true)

      require "hanami/prepare"

      expect(database_urls).to eq(default: "postgres://localhost:5432/app_development")
    end
  end

  it "derives the mysql2 scheme from a \"mysql\" adapter" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "mysql"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("mysql2").and_return(true)

      require "hanami/prepare"

      expect(database_urls).to eq(default: "mysql2://localhost:3306/app_development")
    end
  end

  it "derives the sqlite scheme from a \"sqlite3\" adapter" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite3"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://localhost/app_development")
    end
  end

  it "uses an unrecognised adapter name as the scheme" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "trilogy"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "trilogy://localhost/app_development")
    end
  end

  it "builds gateway URLs from component ENV vars with gateway name suffixes" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_HOST__EXTRA"] = "extra.example.com"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "sqlite://localhost/app_development",
        extra: "sqlite://extra.example.com/extra_development"
      )
    end
  end

  it "builds gateway URLs from the components shared with the default gateway" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "sqlite://hanami@localhost:5432/app_development",
        extra: "sqlite://hanami@localhost:5432/extra_development"
      )
    end
  end

  it "prefers a gateway's DATABASE_URL when it is given alongside component ENV vars" do
    with_app do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["DATABASE_URL__EXTRA"] = "sqlite://db/extra.sqlite3"
      ENV["DATABASE_HOST__EXTRA"] = "extra.example.com"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "sqlite://db/app.sqlite3",
        extra: "sqlite://db/extra.sqlite3"
      )
    end
  end

  it "builds a gateway URL from the default host and port when only its name is given" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "sqlite://localhost/app_development",
        extra: "sqlite://localhost/extra_development"
      )
    end
  end

  it "does not build a gateway URL when no adapter is given for the gateway" do
    with_app do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://db/app.sqlite3")
    end
  end

  it "builds the URL from slice-prefixed component ENV vars" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/relations/.keep", ""
      write "slices/admin/relations/.keep", ""

      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "app.example.com"
      ENV["ADMIN__DATABASE_HOST"] = "admin.example.com"
      ENV["ADMIN__DATABASE_NAME"] = "admin_development"

      require "hanami/prepare"

      admin_database_urls =
        Admin::Slice.container.providers[:db].source.finalize_config.database_urls

      expect(database_urls).to eq(default: "sqlite://app.example.com")
      expect(admin_database_urls).to eq(default: "sqlite://admin.example.com/admin_development")
    end
  end

  it "builds slice gateway URLs from slice-prefixed, gateway-suffixed component ENV vars" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/relations/.keep", ""
      write "slices/admin/relations/.keep", ""

      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "app.example.com"
      ENV["ADMIN__DATABASE_HOST"] = "admin.example.com"
      ENV["ADMIN__DATABASE_NAME__SPECIAL"] = "admin_special_development"
      ENV["ADMIN__DATABASE_HOST__OTHER"] = "other.example.com"

      require "hanami/prepare"

      admin_database_urls =
        Admin::Slice.container.providers[:db].source.finalize_config.database_urls

      expect(database_urls).to eq(default: "sqlite://app.example.com")
      expect(admin_database_urls).to eq(
        default: "sqlite://admin.example.com",
        special: "sqlite://admin.example.com/admin_special_development",
        other: "sqlite://other.example.com"
      )
    end
  end

  it "defaults the host to localhost and the port to the adapter's default port" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "postgres"
      ENV["DATABASE_NAME"] = "app_development"

      allow(Hanami).to receive(:bundled?).and_call_original
      allow(Hanami).to receive(:bundled?).with("pg").and_return(true)

      require "hanami/prepare"

      expect(database_urls).to eq(default: "postgres://localhost:5432/app_development")
    end
  end

  it "omits the port for an adapter without a default port" do
    with_app do
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://hanami@localhost/app_development")
    end
  end

  it "raises an error when no adapter is given" do
    with_app do
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect { database_urls }.to raise_error(Hanami::ComponentLoadError, /database_url/)
    end
  end

  it "transforms the built URL in test mode" do
    with_app do
      ENV["HANAMI_ENV"] = "test"
      ENV["DATABASE_ADAPTER"] = "sqlite"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://localhost/app_test")
    end
  end
end
