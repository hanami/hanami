# frozen_string_literal: true

RSpec.describe "Mailers", :app_integration do
  # Restore the environment after each example, since examples set SMTP_* / HANAMI_ENV vars.
  around do |example|
    env = ENV.to_h
    example.run
  ensure
    ENV.replace(env)
  end

  def write_app(view: true)
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
        end
      end
    RUBY

    return unless view

    write "app/view.rb", <<~RUBY
      module TestApp
        class View < Hanami::View
        end
      end
    RUBY
  end

  def write_welcome_mailer
    write "app/mailers/welcome.rb", <<~RUBY
      module TestApp
        module Mailers
          class Welcome < Hanami::Mailer
            from "noreply@example.com"
            to { |user:| user[:email] }
            subject "Welcome!"

            expose :user
          end
        end
      end
    RUBY
  end

  describe "delivery method provider" do
    it "registers the test delivery method by default" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        require "hanami/prepare"

        expect(Hanami.app["mailers.delivery_method"])
          .to be_a(Hanami::Mailer::Delivery::Test)
      end
    end

    it "builds an SMTP delivery method from SMTP_* env vars, with coercion" do
      ENV["SMTP_ADDRESS"] = "smtp.example.com"
      ENV["SMTP_PORT"] = "2525"
      ENV["SMTP_USERNAME"] = "user"
      ENV["SMTP_PASSWORD"] = "secret"
      ENV["SMTP_AUTHENTICATION"] = "plain"

      with_tmp_directory(Dir.mktmpdir) do
        write_app
        require "hanami/prepare"

        delivery_method = Hanami.app["mailers.delivery_method"]
        expect(delivery_method).to be_a(Hanami::Mailer::Delivery::SMTP)
        expect(delivery_method.instance_variable_get(:@options)).to eq(
          address: "smtp.example.com",
          port: 2525,
          user_name: "user",
          password: "secret",
          authentication: :plain
        )
      end
    end

    it "reads per-slice SMTP env vars, leaving other slices on the default" do
      ENV["ADMIN__SMTP_ADDRESS"] = "smtp.admin.example.com"

      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write "slices/admin/mailers/welcome.rb", <<~RUBY
          module Admin
            module Mailers
              class Welcome < Hanami::Mailer
                from "noreply@example.com"
                to "user@example.com"
                subject "Hi"
              end
            end
          end
        RUBY
        require "hanami/prepare"

        expect(Hanami.app["mailers.delivery_method"])
          .to be_a(Hanami::Mailer::Delivery::Test)

        admin = Hanami.app.slices[:admin]
        expect(admin["mailers.delivery_method"]).to be_a(Hanami::Mailer::Delivery::SMTP)
        expect(admin["mailers.delivery_method"].instance_variable_get(:@options))
          .to eq(address: "smtp.admin.example.com")
      end
    end

    it "falls back to unprefixed SMTP env vars for slices without their own" do
      ENV["SMTP_ADDRESS"] = "smtp.shared.example.com"

      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write "slices/admin/mailers/welcome.rb", <<~RUBY
          module Admin
            module Mailers
              class Welcome < Hanami::Mailer
                from "noreply@example.com"
                to "user@example.com"
                subject "Hi"
              end
            end
          end
        RUBY
        require "hanami/prepare"

        admin = Hanami.app.slices[:admin]
        expect(admin["mailers.delivery_method"]).to be_a(Hanami::Mailer::Delivery::SMTP)
        expect(admin["mailers.delivery_method"].instance_variable_get(:@options))
          .to eq(address: "smtp.shared.example.com")
      end
    end

    it "does not override a user-registered :mailers provider" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write "config/providers/mailers.rb", <<~RUBY
          Hanami.app.register_provider(:mailers, namespace: true) do
            start do
              require "hanami/mailer"
              register "delivery_method", Hanami::Mailer::Delivery::SMTP.new(address: "custom.example.com")
            end
          end
        RUBY
        require "hanami/prepare"

        delivery_method = Hanami.app["mailers.delivery_method"]
        expect(delivery_method).to be_a(Hanami::Mailer::Delivery::SMTP)
        expect(delivery_method.instance_variable_get(:@options))
          .to eq(address: "custom.example.com")
      end
    end

    it "warns (without raising) in production when no SMTP is configured" do
      ENV["HANAMI_ENV"] = "production"
      logger_stream = StringIO.new

      with_tmp_directory(Dir.mktmpdir) do
        write_app
        require "hanami/setup"
        Hanami.app.config.logger.stream = logger_stream
        require "hanami/prepare"

        delivery_method = Hanami.app["mailers.delivery_method"]
        expect(delivery_method).to be_a(Hanami::Mailer::Delivery::Test)

        logger_stream.rewind
        expect(logger_stream.read).to include("No SMTP configuration")
      end
    end
  end

  describe "mailer instances" do
    it "injects the slice's delivery method" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<h1>Hi</h1>\n"
        require "hanami/prepare"

        expect(Hanami.app["mailers.welcome"].delivery_method)
          .to be(Hanami.app["mailers.delivery_method"])
      end
    end

    it "allows the delivery method to be overridden per instance" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<h1>Hi</h1>\n"
        require "hanami/prepare"

        custom = Hanami::Mailer::Delivery::Test.new
        expect(TestApp::Mailers::Welcome.new(delivery_method: custom).delivery_method)
          .to be(custom)
      end
    end

    it "injects the delivery method even for mailers outside a Mailers namespace" do
      # The :mailers provider is namespaced, so it boots when a `mailers.*` key is resolved. A
      # mailer defined elsewhere (e.g. Notifications::Welcome → `notifications.welcome`) must still
      # get the configured delivery method, because its constructor resolves
      # `mailers.delivery_method`, which boots the provider regardless of the mailer's namespace.
      ENV["SMTP_ADDRESS"] = "smtp.example.com"

      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write "app/notifications/welcome.rb", <<~RUBY
          module TestApp
            module Notifications
              class Welcome < Hanami::Mailer
                from "noreply@example.com"
                to "user@example.com"
                subject "Hi"
              end
            end
          end
        RUBY
        require "hanami/prepare"

        # Resolve only the mailer (nothing in the mailers.* namespace) and confirm the provider
        # was booted to supply an SMTP delivery method.
        expect(Hanami.app["notifications.welcome"].delivery_method)
          .to be_a(Hanami::Mailer::Delivery::SMTP)
      end
    end

    it "delivers a rendered message" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<h1>Welcome <%= user[:name] %></h1>\n"
        require "hanami/prepare"

        result = Hanami.app["mailers.welcome"].deliver(
          user: {name: "Alice", email: "alice@example.com"}
        )

        expect(result.message.to).to eq(["alice@example.com"])
        expect(result.message.subject).to eq("Welcome!")
        expect(result.message.html_body).to eq("<h1>Welcome Alice</h1>\n")
        expect(Hanami.app["mailers.delivery_method"].deliveries.length).to eq(1)
      end
    end
  end

  describe "view integration" do
    it "resolves templates from templates/mailers/" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<h1>Hi</h1>\n"
        require "hanami/prepare"

        expect(TestApp::Mailers::Welcome.config.template).to eq("mailers/welcome")
        result = Hanami.app["mailers.welcome"].deliver(user: {email: "a@example.com"})
        expect(result.message.html_body).to eq("<h1>Hi</h1>\n")
      end
    end

    it "renders standard view helpers, including i18n, in mailer templates" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        # Relative key: `.greeting` resolves against the template name, `mailers.welcome`.
        write "config/i18n/en.yml", <<~YAML
          en:
            mailers:
              welcome:
                greeting: "Hello from i18n"
        YAML
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb",
              "<p><%= t(\".greeting\") %>, <%= user[:name] %></p>\n"
        require "hanami/prepare"

        result = Hanami.app["mailers.welcome"].deliver(user: {name: "Bob", email: "b@example.com"})
        expect(result.message.html_body).to eq("<p>Hello from i18n, Bob</p>\n")
      end
    end

    it "builds mailer views from a user-defined <Slice>::Mailers::View when present" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write "app/mailers/view.rb", <<~RUBY
          module TestApp
            module Mailers
              class View < TestApp::View
                expose :brand, default: "ACME"
              end
            end
          end
        RUBY
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<p><%= brand %>: <%= user[:name] %></p>\n"
        require "hanami/prepare"

        result = Hanami.app["mailers.welcome"].deliver(user: {name: "Bob", email: "b@example.com"})
        expect(result.message.html_body).to eq("<p>ACME: Bob</p>\n")
      end
    end

    it "renders mailer templates even when the slice defines no base view class" do
      with_tmp_directory(Dir.mktmpdir) do
        # No base view class (app/view.rb): the auto-defined Mailers::View falls back to
        # Hanami::View and must still be configured for the slice (paths, context, helpers).
        write_app(view: false)
        write "config/i18n/en.yml", <<~YAML
          en:
            mailers:
              greeting: "Hello from i18n"
        YAML
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb",
              "<p><%= t(\"mailers.greeting\") %>, <%= user[:name] %></p>\n"
        require "hanami/prepare"

        result = Hanami.app["mailers.welcome"].deliver(user: {name: "Bob", email: "b@example.com"})
        expect(result.message.html_body).to eq("<p>Hello from i18n, Bob</p>\n")
      end
    end

    it "raises a ComponentLoadError if a mailer template uses request-related features" do
      with_tmp_directory(Dir.mktmpdir) do
        write_app
        write_welcome_mailer
        write "app/templates/mailers/welcome.html.erb", "<p><%= request.inspect %></p>\n"
        require "hanami/prepare"

        expect {
          Hanami.app["mailers.welcome"].deliver(user: {email: "a@example.com"})
        }.to raise_error(Hanami::ComponentLoadError)
      end
    end
  end
end
