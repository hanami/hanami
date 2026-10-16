# frozen_string_literal: true

RSpec.describe "DB / Database URL from ENV components", :app_integration do
  subject(:database_urls) {
    Hanami.app.container.providers[:db].source.finalize_config.database_urls
  }

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)

    allow(Hanami).to receive(:bundled?).and_call_original
    allow(Hanami).to receive(:bundled?).with("pg").and_return(true)
    # The sqlite3 gem is not bundled on JRuby
    allow(Hanami).to receive(:bundled?).with("sqlite3").and_return(true)
    allow(Hanami).to receive(:bundled?).with("jdbc-postgres").and_return(true)
    allow(Hanami).to receive(:bundled?).with("jdbc-sqlite3").and_return(true)
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
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_PASSWORD"] = "s3cret"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://hanami:s3cret@localhost:5432/app_development"
      )
    end
  end

  it "escapes the user, password and database name" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_USER"] = "user@example.com"
      ENV["DATABASE_PASSWORD"] = "p@ss word"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app/dev?"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://user%40example.com:p%40ss%20word@localhost/app/dev%3F"
      )
    end
  end

  it "omits the user, password and database name when they are not given" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5432"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "postgres://localhost:5432")
    end
  end

  it "omits the password when only the user is given" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_HOST"] = "localhost"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "postgres://hanami@localhost")
    end
  end

  it "builds a SQLite URL from the database name alone, ignoring the host, port, user and password" do
    with_app do
      ENV["DATABASE_SCHEME"] = "sqlite"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_PASSWORD"] = "s3cret"
      ENV["DATABASE_HOST"] = "db.example.com"
      ENV["DATABASE_PORT"] = "5432"
      ENV["DATABASE_NAME"] = "db/my app.sqlite3"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://db/my%20app.sqlite3")
    end
  end

  it "builds an absolute SQLite path" do
    with_app do
      ENV["DATABASE_SCHEME"] = "sqlite"
      ENV["DATABASE_NAME"] = "/var/db/app.sqlite3"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite:///var/db/app.sqlite3")
    end
  end

  it "builds gateway URLs from component ENV vars with gateway name suffixes" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_HOST__EXTRA"] = "extra.example.com"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://localhost/app_development",
        extra: "postgres://extra.example.com/extra_development"
      )
    end
  end

  it "builds gateway URLs from the components shared with the default gateway" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_PORT"] = "5433"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://hanami@localhost:5433/app_development",
        extra: "postgres://hanami@localhost:5433/extra_development"
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

  it "builds a gateway URL from the default host when only its name is given" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_NAME"] = "app_development"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "postgres://localhost/app_development",
        extra: "postgres://localhost/extra_development"
      )
    end
  end

  it "raises an error naming the scheme ENV var when a gateway has components but no scheme" do
    with_app do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["DATABASE_NAME__EXTRA"] = "extra_development"

      require "hanami/prepare"

      expect { database_urls }.to raise_error(Hanami::ComponentLoadError, /set DATABASE_SCHEME__EXTRA \(or DATABASE_SCHEME\)/)
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

      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_HOST"] = "app.example.com"
      ENV["ADMIN__DATABASE_HOST"] = "admin.example.com"
      ENV["ADMIN__DATABASE_NAME"] = "admin_development"

      require "hanami/prepare"

      admin_database_urls =
        Admin::Slice.container.providers[:db].source.finalize_config.database_urls

      expect(database_urls).to eq(default: "postgres://app.example.com")
      expect(admin_database_urls).to eq(default: "postgres://admin.example.com/admin_development")
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

      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_HOST"] = "app.example.com"
      ENV["ADMIN__DATABASE_HOST"] = "admin.example.com"
      ENV["ADMIN__DATABASE_NAME__SPECIAL"] = "admin_special_development"
      ENV["ADMIN__DATABASE_HOST__OTHER"] = "other.example.com"

      require "hanami/prepare"

      admin_database_urls =
        Admin::Slice.container.providers[:db].source.finalize_config.database_urls

      expect(database_urls).to eq(default: "postgres://app.example.com")
      expect(admin_database_urls).to eq(
        default: "postgres://admin.example.com",
        special: "postgres://admin.example.com/admin_special_development",
        other: "postgres://other.example.com"
      )
    end
  end

  it "defaults the host to localhost, leaving the port to the driver" do
    with_app do
      ENV["DATABASE_SCHEME"] = "postgres"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "postgres://localhost/app_development")
    end
  end

  it "raises an error naming the scheme ENV var when no scheme is given" do
    with_app do
      ENV["DATABASE_HOST"] = "localhost"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect { database_urls }.to raise_error(Hanami::ComponentLoadError, /set DATABASE_SCHEME to your database URL scheme/)
    end
  end

  it "transforms the built URL in test mode" do
    with_app do
      ENV["HANAMI_ENV"] = "test"
      ENV["DATABASE_SCHEME"] = "sqlite"
      ENV["DATABASE_NAME"] = "db/app_development.sqlite3"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "sqlite://db/app_test.sqlite3")
    end
  end

  it "builds a JDBC URL, giving the user and password as query params" do
    with_app do
      ENV["DATABASE_SCHEME"] = "jdbc:postgresql"
      ENV["DATABASE_USER"] = "hanami"
      ENV["DATABASE_PASSWORD"] = "p@ss word"
      ENV["DATABASE_HOST"] = "db.example.com"
      ENV["DATABASE_PORT"] = "5433"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(
        default: "jdbc:postgresql://db.example.com:5433/app_development?user=hanami&password=p%40ss+word"
      )
    end
  end

  it "builds a JDBC URL without query params when no user or password is given" do
    with_app do
      ENV["DATABASE_SCHEME"] = "jdbc:postgresql"
      ENV["DATABASE_NAME"] = "app_development"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "jdbc:postgresql://localhost/app_development")
    end
  end

  it "builds a JDBC SQLite URL from the database name alone" do
    with_app do
      ENV["DATABASE_SCHEME"] = "jdbc:sqlite"
      ENV["DATABASE_HOST"] = "db.example.com"
      ENV["DATABASE_NAME"] = "/var/db/app.sqlite3"

      require "hanami/prepare"

      expect(database_urls).to eq(default: "jdbc:sqlite:/var/db/app.sqlite3")
    end
  end
end
