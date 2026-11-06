# frozen_string_literal: true

require "rack/test"

RSpec.describe "Validation / I18n", :app_integration do
  include Rack::Test::Methods

  let(:app) { Hanami.app }

  before do
    require "i18n"
    require "dry/validation"
  end

  def write_app
    write "config/app.rb", <<~RUBY
      require "hanami"

      module TestApp
        class App < Hanami::App
          config.logger.stream = StringIO.new
        end
      end
    RUBY

    write "config/i18n/en.yml", <<~YAML
      en:
        greeting: Hello
    YAML

    write "config/i18n/fr.yml", <<~YAML
      fr:
        dry_validation:
          errors:
            filled?: "doit être rempli"
            min_size?: "doit contenir au moins %{num} caractères"
            taken: "est déjà pris"
          rules:
            name: nom
    YAML

    write "app/contracts/user_contract.rb", <<~RUBY
      module TestApp
        module Contracts
          class UserContract < Dry::Validation::Contract
            params do
              required(:name).filled(:string, min_size?: 3)
            end

            rule(:name) do
              key.failure(:taken) if value == "taken"
            end
          end
        end
      end
    RUBY
  end

  it "translates contract messages using the slice's i18n and current locale" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app
      require "hanami/prepare"

      contract = TestApp::Contracts::UserContract.new
      i18n = Hanami.app["i18n"]

      expect(contract.(name: "").errors.to_h).to eq(name: ["must be filled"])

      i18n.with_locale(:fr) do
        expect(contract.(name: "").errors.to_h).to eq(name: ["doit être rempli"])
        expect(contract.(name: "ab").errors.to_h).to eq(name: ["doit contenir au moins 3 caractères"])
        expect(contract.(name: "taken").errors.to_h).to eq(name: ["est déjà pris"])
        expect(contract.(name: "").errors(full: true).to_h).to eq(name: ["nom doit être rempli"])
      end

      expect(contract.(name: "").errors(locale: :fr).to_h).to eq(name: ["doit être rempli"])
    end
  end

  it "falls back to the bundled English messages for untranslated keys" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app
      require "hanami/prepare"

      contract = TestApp::Contracts::UserContract.new

      Hanami.app["i18n"].with_locale(:fr) do
        expect(contract.(name: 123).errors.to_h).to eq(name: ["must be a string"])
      end
    end
  end

  it "uses the app's default locale" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
            config.logger.stream = StringIO.new
            config.i18n.default_locale = :fr
          end
        end
      RUBY
      require "hanami/prepare"

      expect(TestApp::Contracts::UserContract.new.(name: "").errors.to_h).to eq(name: ["doit être rempli"])
    end
  end

  it "uses each slice's own translations, including for subclasses of an app base contract" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app

      write "slices/admin/config/i18n/fr.yml", <<~YAML
        fr:
          dry_validation:
            errors:
              filled?: "est obligatoire"
      YAML

      write "app/contract.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Contract < Dry::Validation::Contract
          end
        end
      RUBY

      write "slices/admin/contracts/user_contract.rb", <<~RUBY
        module Admin
          module Contracts
            class UserContract < TestApp::Contract
              params do
                required(:name).filled(:string)
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      Admin::Slice.boot
      Hanami.app["i18n"].locale = :fr
      Admin::Slice["i18n"].locale = :fr

      expect(TestApp::Contracts::UserContract.new.(name: "").errors.to_h).to eq(name: ["doit être rempli"])
      expect(Admin::Contracts::UserContract.new.(name: "").errors.to_h).to eq(name: ["est obligatoire"])
    ensure
      Hanami.app["i18n"].locale = nil
      Admin::Slice["i18n"].locale = nil
    end
  end

  it "translates messages for contracts given to actions as blocks" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app

      write "config/routes.rb", <<~RUBY
        module TestApp
          class Routes < Hanami::Routes
            post "/users", to: "users.create"
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      write "app/actions/users/create.rb", <<~RUBY
        module TestApp
          module Actions
            module Users
              class Create < TestApp::Action
                params do
                  required(:name).filled(:string)
                end

                def handle(request, response)
                  response.body = request.params.errors.to_h.inspect
                end
              end
            end
          end
        end
      RUBY

      require "hanami/boot"

      # Action params are validated before any action callbacks run, so the locale must be set
      # before the action is called (e.g. by middleware)
      Hanami.app["i18n"].with_locale(:fr) do
        post "/users", {name: ""}
      end

      expect(last_response.body).to eq({name: ["doit être rempli"]}.inspect)
    end
  end

  it "supports contracts with custom messages load paths and top namespace" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app

      write "config/i18n/de.yml", <<~YAML
        de:
          my_app:
            errors:
              filled?: "muss ausgefüllt sein"
      YAML

      write "config/contract_errors.yml", <<~YAML
        en:
          my_app:
            errors:
              filled?: "is required"
      YAML

      write "app/contracts/custom_contract.rb", <<~RUBY
        module TestApp
          module Contracts
            class CustomContract < Dry::Validation::Contract
              config.messages.top_namespace = "my_app"
              config.messages.load_paths << File.join(__dir__, "../../config/contract_errors.yml")

              params do
                required(:name).filled(:string)
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      contract = TestApp::Contracts::CustomContract.new

      expect(contract.(name: "").errors.to_h).to eq(name: ["is required"])
      expect(contract.(name: 1).errors.to_h).to eq(name: ["must be a string"])
      expect(contract.(name: "").errors(locale: :de).to_h).to eq(name: ["muss ausgefüllt sein"])
    end
  end

  it "leaves contracts with an explicitly configured messages backend alone" do
    with_tmp_directory(Dir.mktmpdir) do
      write_app

      write "app/contracts/plain_contract.rb", <<~RUBY
        module TestApp
          module Contracts
            class PlainContract < Dry::Validation::Contract
              config.messages.backend = :yaml

              params do
                required(:name).filled(:string)
              end
            end
          end
        end
      RUBY

      require "hanami/prepare"

      Hanami.app["i18n"].with_locale(:fr) do
        expect(TestApp::Contracts::PlainContract.new.(name: "").errors.to_h).to eq(name: ["must be filled"])
      end
    end
  end

  it "leaves contracts defined outside an app alone" do
    require "hanami"

    contract_class = Class.new(Dry::Validation::Contract) {
      params { required(:name).filled(:string) }
    }

    expect(contract_class.new.(name: "").errors.to_h).to eq(name: ["must be filled"])
  end
end
