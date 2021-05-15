# frozen_string_literal: true

require "hanami/application/settings/loader"
require "dotenv"

RSpec.describe Hanami::Application::Settings::Loader do
  subject(:loader) { described_class.new }

  def build_config(&block)
    Class.new do
      include Dry::Configurable
    end.tap { |klass| klass.instance_eval(&block) if block_given? }.new.config
  end

  describe "#call" do
    subject(:loaded_settings) { loader.load(config).to_h }

    let(:config) { build_config }

    describe "loading dotenv" do
      context "dotenv available" do
        let(:dotenv) { spy(:dotenv) }

        before do
          allow(loader).to receive(:require).and_call_original
          stub_const "Dotenv", dotenv
        end

        it "requires and loads a range of dotenv files, specific to the current HANAMI_ENV" do
          loaded_settings

          expect(loader).to have_received(:require).with("dotenv").ordered
          expect(dotenv).to have_received(:load).ordered.with(
            ".env.development.local",
            ".env.local",
            ".env.development",
            ".env"
          )
        end

        context "HANAMI_ENV is 'test'" do
          before do
            @hanami_env = ENV["HANAMI_ENV"]
            ENV["HANAMI_ENV"] = "test"
          end

          after do
            ENV["HANAMI_ENV"] = @hanami_env
          end

          it "does not load .env.local (which is intended for non-test settings only)" do
            loaded_settings

            expect(dotenv).to have_received(:load).ordered.with(
              ".env.test.local",
              ".env.test",
              ".env"
            )
          end
        end
      end

      context "dotenv unavailable" do
        before do
          allow(loader).to receive(:require).with("dotenv").and_raise LoadError
        end

        it "attempts to require dotenv" do
          loaded_settings
          expect(loader).to have_received(:require).with("dotenv")
        end

        it "gracefully ignores load errors" do
          expect { loaded_settings }.not_to raise_error
        end
      end
    end

    describe "loading settings" do
      let(:env) {
        {
          "DATABASE_URL" => "postgres://localhost/test_app_development",
          "REDIS_URL" => "redis://localhost:6379",
        }
      }

      before do
        stub_const "ENV", env
      end

      context "no setting definition argument provided" do
        let(:config) {
          build_config do
            setting :database_url, []
          end
        }

        it "returns hash of settings from ENV" do
          expect(loaded_settings).to eq(database_url: "postgres://localhost/test_app_development")
        end
      end

      context "callable setting definition arguments provided" do
        let(:config) {
          build_config do
            setting :database_url, constructor: ->(v) { v.split("/").last }
            setting :redis_url, []
          end
        }

        it "returns a hash of settings from ENV, with setting values passed through their callable arguments" do
          expect(loaded_settings).to eq(
            database_url: "test_app_development",
            redis_url: "redis://localhost:6379",
          )
        end

        context "callable definition arguments fail" do
          let(:config) {
            build_config do
              setting :database_url, constructor: ->(_v) { raise "nope to database" }
              setting :redis_url, constructor: ->(_v) { raise "nope to redis" }
            end
          }

          it "raises an error for all failed settings" do
            expect { loaded_settings }.to raise_error(
              described_class::InvalidSettingsError,
              /(database_url: nope to database).*(redis_url: nope to redis)/m,
            )
          end
        end
      end
    end
  end
end
