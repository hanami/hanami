# frozen_string_literal: true

RSpec.describe "I18n", :app_integration do
  context "i18n gem is available" do
    before do
      require "i18n"
    end

    it "provides a complete i18n API" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello, %{name}!
            messages:
              welcome: Welcome to our app
              nested:
                deep: Deep nested message
            date:
              formats:
                short: "%b %d"
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour, %{name}!
            messages:
              welcome: Bienvenue dans notre application
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Basic translation
        expect(i18n.t("messages.welcome")).to eq "Welcome to our app"
        expect(i18n.translate("messages.welcome")).to eq "Welcome to our app"

        # Translation with interpolation
        expect(i18n.t("greeting", name: "Alice")).to eq "Hello, Alice!"

        # Nested keys
        expect(i18n.t("messages.nested.deep")).to eq "Deep nested message"

        # Translation with explicit locale
        expect(i18n.t("greeting", name: "Bob", locale: :fr)).to eq "Bonjour, Bob!"

        # exists? method
        expect(i18n.exists?("messages.welcome")).to be true
        expect(i18n.exists?("missing.key")).to be false

        # Missing translations return key as string by default
        expect(i18n.t("missing.key")).to eq "missing.key"

        # t! raises for missing translations
        expect { i18n.t!("missing.key") }.to raise_error(I18n::MissingTranslationData)

        # Locale management
        expect(i18n.locale).to eq :en
        expect(i18n.default_locale).to eq :en

        # available_locales
        expect(i18n.available_locales).to contain_exactly(:en, :fr)

        # Locale switching
        i18n.locale = :fr
        expect(i18n.t("greeting", name: "Charlie")).to eq "Bonjour, Charlie!"
        i18n.locale = :en
        expect(i18n.t("greeting", name: "Charlie")).to eq "Hello, Charlie!"

        i18n.with_locale(:fr) do
          expect(i18n.t("messages.welcome")).to eq "Bienvenue dans notre application"
        end
        expect(i18n.locale).to eq :en
      end
    end

    it "allows configuring default_locale" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :fr
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello!
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour!
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        expect(i18n.default_locale).to eq :fr
        expect(i18n.t("greeting")).to eq "Bonjour!"
        expect(i18n.t("greeting", locale: :en)).to eq "Hello!"
      end
    end

    it "works with different files and settings across slices" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            app_message: This is the app
        YAML

        write "slices/admin/config/i18n/en.yml", <<~YAML
          en:
            admin_message: Admin area
            shared: Admin shared message
        YAML

        write "slices/admin/config/i18n/fr.yml", <<~YAML
          fr:
            admin_message: Zone d'administration
            shared: Message partagé admin
        YAML

        write "config/slices/main.rb", <<~RUBY
          module Main
            class Slice < Hanami::Slice
              config.i18n.default_locale = :fr
            end
          end
        RUBY

        write "slices/main/config/i18n/en.yml", <<~YAML
          en:
            main_message: Main endpoint
            shared: Main shared message
        YAML

        write "slices/main/config/i18n/fr.yml", <<~YAML
          fr:
            main_message: Point de terminaison principal
            shared: Message partagé principal
        YAML

        require "hanami/prepare"

        # App has its own translations
        app_i18n = Hanami.app["i18n"]
        expect(app_i18n.t("app_message")).to eq "This is the app"
        expect(app_i18n.default_locale).to eq :en

        # Admin slice has its own translations with default :en locale
        admin_i18n = Admin::Slice["i18n"]
        expect(admin_i18n.t("admin_message")).to eq "Admin area"
        expect(admin_i18n.t("shared")).to eq "Admin shared message"
        expect(admin_i18n.t("admin_message", locale: :fr)).to eq "Zone d'administration"
        expect(admin_i18n.default_locale).to eq :en

        # Main slice has its own translations with configured :fr locale
        main_i18n = Main::Slice["i18n"]
        expect(main_i18n.t("main_message")).to eq "Point de terminaison principal"
        expect(main_i18n.t("shared")).to eq "Message partagé principal"
        expect(main_i18n.t("main_message", locale: :en)).to eq "Main endpoint"
        expect(main_i18n.default_locale).to eq :fr

        # Slices don't see each other's translations
        expect { admin_i18n.t("main_message", raise: true) }.to raise_error(I18n::MissingTranslationData)
        expect { main_i18n.t("admin_message", raise: true) }.to raise_error(I18n::MissingTranslationData)
        expect { app_i18n.t("admin_message", raise: true) }.to raise_error(I18n::MissingTranslationData)
      end
    end

    it "allows configuring available_locales" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.available_locales = [:en, :fr]
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello!
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour!
        YAML

        write "config/i18n/de.yml", <<~YAML
          de:
            greeting: Guten Tag!
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Only configured locales are available, even though de.yml exists
        expect(i18n.available_locales).to contain_exactly(:en, :fr)
        expect(i18n.available_locales).not_to include(:de)
      end
    end

    it "returns all detected locales when available_locales is not configured" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello!
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour!
        YAML

        write "config/i18n/de.yml", <<~YAML
          de:
            greeting: Guten Tag!
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # All loaded locales are available when not configured
        expect(i18n.available_locales).to contain_exactly(:en, :fr, :de)
      end
    end

    it "allows different available_locales per slice" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.available_locales = [:en]
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            app_message: App message
        YAML

        write "slices/search/config/i18n/en.yml", <<~YAML
          en:
            search_message: Search message
        YAML

        write "slices/search/config/i18n/fr.yml", <<~YAML
          fr:
            search_message: Message de recherche
        YAML

        write "slices/search/config/i18n/de.yml", <<~YAML
          de:
            search_message: Suchnachricht
        YAML

        write "config/slices/search.rb", <<~RUBY
          module Search
            class Slice < Hanami::Slice
              config.i18n.available_locales = [:en, :fr, :de]
            end
          end
        RUBY

        require "hanami/prepare"

        app_i18n = Hanami.app["i18n"]
        search_i18n = Search::Slice["i18n"]

        expect(app_i18n.available_locales).to contain_exactly(:en)
        expect(search_i18n.available_locales).to contain_exactly(:en, :fr, :de)
      end
    end

    it "allows configuring via provider with custom backend" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello!
        YAML

        write "config/providers/i18n.rb", <<~'RUBY'
          Hanami.app.configure_provider(:i18n) do
            configure do |config|
              config.default_locale = :fr
              config.available_locales = [:fr, :de]
            end

            before :start do
              # Create a custom backend
              backend = I18n::Backend::Simple.new

              # Store custom translations directly
              backend.store_translations(:fr, { greeting: "Bonjour depuis provider!" })
              backend.store_translations(:de, { greeting: "Hallo vom Provider!" })

              config.backend = backend
            end
          end
        RUBY

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Provider-level config takes precedence
        expect(i18n.default_locale).to eq :fr
        expect(i18n.available_locales).to contain_exactly(:fr, :de)

        # Custom backend is used
        expect(i18n.t("greeting")).to eq "Bonjour depuis provider!"
        expect(i18n.t("greeting", locale: :de)).to eq "Hallo vom Provider!"
      end
    end

    it "supports locale fallbacks" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
              config.i18n.fallbacks = true
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello
            messages:
              welcome: Welcome
        YAML

        write "config/i18n/de.yml", <<~YAML
          de:
            greeting: Hallo
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Translation exists in German
        expect(i18n.t("greeting", locale: :de)).to eq "Hallo"

        # Translation missing in German, falls back to English
        expect(i18n.t("messages.welcome", locale: :de)).to eq "Welcome"
      end
    end

    it "supports custom fallback configuration with hash" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
              config.i18n.fallbacks = {de: [:de, :en], fr: [:fr, :en]}
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello
            messages:
              welcome: Welcome
        YAML

        write "config/i18n/de.yml", <<~YAML
          de:
            greeting: Hallo
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # German falls back to English for missing translations
        expect(i18n.t("greeting", locale: :de)).to eq "Hallo"
        expect(i18n.t("messages.welcome", locale: :de)).to eq "Welcome"

        # French falls back to English for missing translations
        expect(i18n.t("greeting", locale: :fr)).to eq "Bonjour"
        expect(i18n.t("messages.welcome", locale: :fr)).to eq "Welcome"
      end
    end

    it "supports fallbacks with array configuration (default fallback for all locales)" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
              config.i18n.fallbacks = [:en]
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello
            messages:
              welcome: Welcome
        YAML

        write "config/i18n/de.yml", <<~YAML
          de:
            greeting: Hallo
        YAML

        write "config/i18n/fr.yml", <<~YAML
          fr:
            greeting: Bonjour
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # All locales fall back to English for missing translations
        expect(i18n.t("greeting", locale: :de)).to eq "Hallo"
        expect(i18n.t("messages.welcome", locale: :de)).to eq "Welcome"
        expect(i18n.t("greeting", locale: :fr)).to eq "Bonjour"
        expect(i18n.t("messages.welcome", locale: :fr)).to eq "Welcome"
      end
    end

    it "does not apply fallbacks when using a custom backend" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.default_locale = :en
              config.i18n.fallbacks = true
            end
          end
        RUBY

        write "config/providers/i18n.rb", <<~RUBY
          Hanami.app.register_provider :i18n, namespace: true do
            prepare do
              require "i18n"
            end

            start do
              backend = I18n::Backend::Simple.new
              backend.store_translations(:en, {greeting: "Hello from custom backend"})
              backend.store_translations(:de, {custom: "Hallo"})

              register "backend", Hanami::Providers::I18n::Backend.new(
                backend,
                default_locale: :en,
                available_locales: [:en, :de]
              )
            end
          end
        RUBY

        require "hanami/prepare"

        i18n = Hanami.app["i18n.backend"]

        # Custom backend is used
        expect(i18n.t("greeting")).to eq "Hello from custom backend"

        # Fallbacks are NOT applied because a custom backend was provided
        # (fallbacks are only auto-configured for the default Simple backend)
        expect(i18n.t("greeting", locale: :de)).to eq "greeting"
      end
    end

    it "allows appending to default load_path with +=" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.load_path += Dir[
                root.join("config/custom_translations/**/*.yml")
              ]
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            greeting: Hello from default!
        YAML

        write "config/custom_translations/en.yml", <<~YAML
          en:
            custom_message: Hello from custom path!
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Both default and custom paths are loaded
        expect(i18n.t("greeting")).to eq "Hello from default!"
        expect(i18n.t("custom_message")).to eq "Hello from custom path!"
      end
    end

    it "uses only configured load_path when set, ignoring default" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.i18n.load_path = Dir[root.join("translations/**/*.yml")]
            end
          end
        RUBY

        write "config/i18n/en.yml", <<~YAML
          en:
            default_message: This should not be loaded
        YAML

        write "translations/en.yml", <<~YAML
          en:
            custom_message: Only custom path loaded!
        YAML

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]

        # Only custom path is loaded
        expect(i18n.t("custom_message")).to eq "Only custom path loaded!"
        expect(i18n.t("default_message")).to eq "default_message" # Missing translation
      end
    end

    it "does not register the provider when config/i18n/ directory does not exist" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        # No config/i18n/ directory exists

        require "hanami/prepare"

        # Provider should not be registered
        expect(Hanami.app.key?("i18n")).to be false
      end
    end

    it "allows manual registration via provider file even without config/i18n/ directory" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/providers/i18n.rb", <<~'RUBY'
          Hanami.app.configure_provider(:i18n) do
            configure do |config|
              config.default_locale = :es
              config.load_path = ["translations/**/*.yml"]
            end
          end
        RUBY

        write "translations/es.yml", <<~YAML
          es:
            custom_message: Mensaje personalizado
        YAML

        # No config/i18n/ directory exists

        require "hanami/prepare"

        i18n = Hanami.app["i18n"]
        expect(i18n.t("custom_message")).to eq "Mensaje personalizado"
      end
    end

    describe "multi-slice patterns" do
      # Pattern: Full isolation (default behavior).
      #
      # - Each slice has completely separate translations.
      # - No sharing of translation files between app and slices.
      # - Each slice manages its own i18n configuration independently.
      # - Best for apps where slices represent distinct bounded contexts.
      specify "full isolation between slices (default behavior)" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.i18n.default_locale = :en
              end
            end
          RUBY

          write "config/i18n/en.yml", <<~YAML
            en:
              app_message: App only
          YAML

          write "slices/admin/config/i18n/en.yml", <<~YAML
            en:
              admin_message: Admin only
          YAML

          write "slices/main/config/i18n/en.yml", <<~YAML
            en:
              main_message: Main only
          YAML

          require "hanami/prepare"

          app_i18n = Hanami.app["i18n"]
          admin_i18n = Admin::Slice["i18n"]
          main_i18n = Main::Slice["i18n"]

          # Each slice has its own i18n instance
          expect(app_i18n).not_to be(admin_i18n)
          expect(admin_i18n).not_to be(main_i18n)

          # Each has completely isolated translations
          expect(app_i18n.t("app_message")).to eq "App only"
          expect(app_i18n.t("admin_message")).to eq "admin_message" # Missing
          expect(app_i18n.t("main_message")).to eq "main_message" # Missing

          expect(admin_i18n.t("admin_message")).to eq "Admin only"
          expect(admin_i18n.t("app_message")).to eq "app_message" # Missing
          expect(admin_i18n.t("main_message")).to eq "main_message" # Missing

          expect(main_i18n.t("main_message")).to eq "Main only"
          expect(main_i18n.t("app_message")).to eq "app_message" # Missing
          expect(main_i18n.t("admin_message")).to eq "admin_message" # Missing
        end
      end

      # Pattern: Full sharing via shared_app_component_keys.
      #
      # - One i18n instance shared across app and all slices.
      # - All slices see the same translations.
      # - All slices share the same locale settings.
      # - The simplest approach for apps that don't need per-slice translations.
      specify "full sharing via shared_app_component_keys" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.i18n.default_locale = :en
                config.shared_app_component_keys += ["i18n"]
              end
            end
          RUBY

          write "config/i18n/en.yml", <<~YAML
            en:
              shared_message: Shared across all slices
              app_only: App only message
          YAML

          write "config/i18n/fr.yml", <<~YAML
            fr:
              shared_message: Partagé entre toutes les tranches
          YAML

          write "slices/admin/action.rb", <<~RUBY
            module Admin
              class Action
              end
            end
          RUBY

          write "slices/main/action.rb", <<~RUBY
            module Main
              class Action
              end
            end
          RUBY

          require "hanami/prepare"

          app_i18n = Hanami.app["i18n"]
          admin_i18n = Admin::Slice["i18n"]
          main_i18n = Main::Slice["i18n"]

          # All slices share the same i18n instance
          expect(app_i18n).to be(admin_i18n)
          expect(app_i18n).to be(main_i18n)

          # All can access the same translations
          expect(app_i18n.t("shared_message")).to eq "Shared across all slices"
          expect(admin_i18n.t("shared_message")).to eq "Shared across all slices"
          expect(main_i18n.t("shared_message")).to eq "Shared across all slices"

          # All share the same locale
          expect(app_i18n.default_locale).to eq :en
          expect(admin_i18n.default_locale).to eq :en
          expect(main_i18n.default_locale).to eq :en

          # Locale changes affect all slices
          admin_i18n.locale = :fr
          expect(app_i18n.t("shared_message")).to eq "Partagé entre toutes les tranches"
          expect(main_i18n.t("shared_message")).to eq "Partagé entre toutes les tranches"
        end
      end

      # Pattern: Shared base translations with slice-specific overrides.
      #
      # - App uses absolute paths in load_path so slices inherit them.
      # - Each slice has its own i18n instance.
      # - Slices can add their own translations that extend/override app translations.
      # - Slices can have different locale settings.
      # - Best for apps with shared base translations (e.g. for validations, common UI), plus
      #   slice-specific translations.
      specify "shared base translations with slice overrides via absolute paths" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.i18n.default_locale = :en
                # Use absolute path so slices inherit access to app translations
                config.i18n.load_path = [
                  root.join("config/i18n/**/*.yml").to_s
                ]
              end
            end
          RUBY

          write "config/slices/admin.rb", <<~RUBY
            module Admin
              class Slice < Hanami::Slice
                # Add slice-specific translations to inherited load_path
                config.i18n.load_path += ["config/i18n/**/*.yml"]
              end
            end
          RUBY

          write "config/slices/main.rb", <<~RUBY
            module Main
              class Slice < Hanami::Slice
                config.i18n.load_path += ["config/i18n/**/*.yml"]
              end
            end
          RUBY

          write "config/i18n/en.yml", <<~YAML
            en:
              shared_message: Shared from app
              validation:
                required: This field is required
          YAML

          write "config/i18n/fr.yml", <<~YAML
            fr:
              shared_message: Partagé depuis l'application
              validation:
                required: Ce champ est requis
          YAML

          write "slices/admin/config/i18n/en.yml", <<~YAML
            en:
              admin_message: Admin specific
              shared_message: Admin override
          YAML

          write "slices/admin/config/i18n/fr.yml", <<~YAML
            fr:
              admin_message: Spécifique à l'admin
          YAML

          write "slices/main/config/i18n/en.yml", <<~YAML
            en:
              main_message: Main specific
          YAML

          require "hanami/prepare"

          app_i18n = Hanami.app["i18n"]
          admin_i18n = Admin::Slice["i18n"]
          main_i18n = Main::Slice["i18n"]

          # Each slice has its own i18n instance
          expect(app_i18n).not_to be(admin_i18n)
          expect(admin_i18n).not_to be(main_i18n)

          # App has only its own translations
          expect(app_i18n.t("shared_message")).to eq "Shared from app"
          expect(app_i18n.t("validation.required")).to eq "This field is required"
          expect(app_i18n.t("admin_message")).to eq "admin_message" # Missing

          # Admin inherits app translations and adds its own
          expect(admin_i18n.t("shared_message")).to eq "Admin override" # Overridden
          expect(admin_i18n.t("validation.required")).to eq "This field is required" # Inherited
          expect(admin_i18n.t("admin_message")).to eq "Admin specific"

          # Admin can override in some locales but not others
          expect(admin_i18n.t("shared_message", locale: :fr)).to eq "Partagé depuis l'application"

          # Main inherits app translations and adds its own
          expect(main_i18n.t("shared_message")).to eq "Shared from app" # Inherited
          expect(main_i18n.t("validation.required")).to eq "This field is required" # Inherited
          expect(main_i18n.t("main_message")).to eq "Main specific"

          # Slices don't see each other's specific translations
          expect(admin_i18n.t("main_message")).to eq "main_message" # Missing
          expect(main_i18n.t("admin_message")).to eq "admin_message" # Missing
        end
      end

      # Pattern: Mix and match.
      #
      # - Some slices can share app i18n via shared_app_component_keys.
      # - Other slices can opt out and have isolated translations.
      # - Demonstrates per-slice control over sharing behavior.
      it "supports mixing patterns: some slices share, others are isolated" do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
                config.i18n.default_locale = :en
                # Admin and Main will share app i18n
                config.shared_app_component_keys += ["i18n"]
              end
            end
          RUBY

          write "config/slices/search.rb", <<~RUBY
            module Search
              class Slice < Hanami::Slice
                # Override to remove i18n from shared components for this slice
                config.shared_app_component_keys -= ["i18n"]
              end
            end
          RUBY

          write "config/i18n/en.yml", <<~YAML
            en:
              shared: Shared message
          YAML

          # Admin and Main will share app i18n (no config/i18n dir needed)
          write "slices/admin/action.rb", <<~RUBY
            module Admin
              class Action
              end
            end
          RUBY

          write "slices/main/action.rb", <<~RUBY
            module Main
              class Action
              end
            end
          RUBY

          # Search has its own isolated i18n
          write "slices/search/config/i18n/en.yml", <<~YAML
            en:
              search_message: Search only
          YAML

          require "hanami/prepare"

          app_i18n = Hanami.app["i18n"]
          admin_i18n = Admin::Slice["i18n"]
          main_i18n = Main::Slice["i18n"]
          search_i18n = Search::Slice["i18n"]

          # Admin and Main share app i18n
          expect(admin_i18n).to be(app_i18n)
          expect(main_i18n).to be(app_i18n)
          expect(admin_i18n.t("shared")).to eq "Shared message"
          expect(main_i18n.t("shared")).to eq "Shared message"

          # Search has its own isolated i18n
          expect(search_i18n).not_to be(app_i18n)
          expect(search_i18n.t("search_message")).to eq "Search only"
          expect(search_i18n.t("shared")).to eq "shared" # Missing
        end
      end
    end
  end
end
