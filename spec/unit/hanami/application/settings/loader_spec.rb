# frozen_string_literal: true

require "hanami/application/settings/loader"
require "dotenv"

RSpec.describe Hanami::Application::Settings::Loader do
  subject(:loader) { described_class.new }

  describe "#call" do
    subject(:loaded_settings) { loader.call(defined_settings) }

    let(:defined_settings) { [] }

    describe "loading dotenv" do
      context "dotenv available" do
        let(:dotenv) { spy(:dotenv) }

        before do
          allow(loader).to receive(:require).and_call_original
          stub_const "Dotenv", dotenv
        end

        it "requires and loads dotenv" do
          loaded_settings
          expect(loader).to have_received(:require).with("dotenv").ordered
          expect(dotenv).to have_received(:load).ordered
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
        let(:defined_settings) {
          [
            [:database_url, []]
          ]
        }

        it "returns hash of settings from ENV" do
          expect(loaded_settings).to eq(database_url: "postgres://localhost/test_app_development")
        end
      end

      context "callable setting definition arguments provided" do
        let(:defined_settings) {
          [
            [:database_url, [->(v) { v.split("/").last }]],
            [:redis_url, []],
          ]
        }

        it "returns a hash of settings from ENV, with setting values passed through their callable arguments" do
          expect(loaded_settings).to eq(
            database_url: "test_app_development",
            redis_url: "redis://localhost:6379",
          )
        end

        context "callable definition arguments fail" do
          let(:defined_settings) {
            [
              [:database_url, [->(_v) { raise "nope to database" }]],
              [:redis_url, [->(_v) { raise "nope to redis" }]],
            ]
          }

          it "raises an error for all failed settings" do
            expect { loaded_settings }.to raise_error(
              described_class::InvalidSettingsError,
              /(database_url: nope to database).*(redis_url: nope to redis)/m,
            )
          end
        end
      end

      context "unsupported setting definition argument provided" do
        let(:defined_settings) {
          [
            [:database_url, ["unsupported"]],
          ]
        }

        it "raises an error" do
          expect { loaded_settings }.to raise_error(
            described_class::UnsupportedSettingArgumentError,
            'Unsupported arguments ["unsupported"] for setting +database_url+'
          )
        end
      end
    end
  end
end
