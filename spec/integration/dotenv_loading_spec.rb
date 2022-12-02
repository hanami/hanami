# frozen_string_literal: true

# rubocop:disable Style/FetchEnvVar

RSpec.describe "Dotenv loading", :app_integration do
  before do
    @orig_env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@orig_env)
  end

  context "dotenv gem is available" do
    before do
      require "dotenv"
    end

    context "hanami env is development" do
      it "loads .env.development.local, .env.local, .env.development and .env (in this order) into ENV", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env.development.local", <<~'TEXT'
            FROM_SPECIFIC_ENV_LOCAL="from .env.development.local"
          TEXT

          write ".env.local", <<~'TEXT'
            FROM_BASE_LOCAL="from .env.local"
            FROM_SPECIFIC_ENV_LOCAL=nope
          TEXT

          write ".env.development", <<~'TEXT'
            FROM_SPECIFIC_ENV="from .env.development"
            FROM_SPECIFIC_ENV_LOCAL=nope
            FROM_BASE_LOCAL=nope
          TEXT

          write ".env", <<~'TEXT'
            FROM_BASE="from .env"
            FROM_SPECIFIC_ENV_LOCAL=nope
            FROM_BASE_LOCAL=nope
            FROM_SPECIFIC_ENV=nope
          TEXT

          ENV["HANAMI_ENV"] = "development"

          require "hanami/setup"

          expect(ENV["FROM_SPECIFIC_ENV_LOCAL"]).to eq "from .env.development.local"
          expect(ENV["FROM_BASE_LOCAL"]).to eq "from .env.local"
          expect(ENV["FROM_SPECIFIC_ENV"]).to eq "from .env.development"
          expect(ENV["FROM_BASE"]).to eq "from .env"
        end
      end
    end

    context "hanami env is test" do
      it "loads .env.development.local, .env.development and .env (in this order) into ENV", :aggregate_failures do
        with_tmp_directory(Dir.mktmpdir) do
          write "config/app.rb", <<~'RUBY'
            require "hanami"

            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write ".env.test.local", <<~'TEXT'
            FROM_SPECIFIC_ENV_LOCAL="from .env.test.local"
          TEXT

          write ".env.local", <<~'TEXT'
            FROM_BASE_LOCAL="from .env.local"
          TEXT

          write ".env.test", <<~'TEXT'
            FROM_SPECIFIC_ENV="from .env.test"
            FROM_SPECIFIC_ENV_LOCAL=nope
          TEXT

          write ".env", <<~'TEXT'
            FROM_BASE="from .env"
            FROM_SPECIFIC_ENV_LOCAL=nope
            FROM_SPECIFIC_ENV=nope
          TEXT

          ENV["HANAMI_ENV"] = "test"

          require "hanami/prepare"

          expect(ENV["FROM_SPECIFIC_ENV_LOCAL"]).to eq "from .env.test.local"
          expect(ENV["FROM_BASE_LOCAL"]).to be nil
          expect(ENV["FROM_SPECIFIC_ENV"]).to eq "from .env.test"
          expect(ENV["FROM_BASE"]).to eq "from .env"
        end
      end
    end
  end

  context "dotenv gem is unavailable" do
    before do
      allow_any_instance_of(Object).to receive(:gem).and_call_original
      allow_any_instance_of(Object).to receive(:gem).with("dotenv").and_raise(Gem::LoadError)
    end

    it "does not load from .env files" do
      with_tmp_directory(Dir.mktmpdir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write ".env", <<~'TEXT'
          FOO=bar
        TEXT

        expect { require "hanami/prepare" }.not_to(change { ENV.to_h })
        expect(ENV.key?("FOO")).to be false
      end
    end
  end
end

# rubocop:enable Style/FetchEnvVar
