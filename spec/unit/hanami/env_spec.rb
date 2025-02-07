# frozen_string_literal: true

RSpec.describe Hanami, ".env" do
  subject { described_class.env(e: env) }

  context "HANAMI_ENV, APP_ENV and RACK_ENV in ENV" do
    let(:env) { { "HANAMI_ENV" => "test", "APP_ENV" => "development", "RACK_ENV" => "production" } }

    it "is the value of HANAMI_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "APP_ENV and RACK_ENV in ENV" do
    let(:env) { {"APP_ENV" => "development", "RACK_ENV" => "production" } }

    it "is the value of APP_ENV" do
      is_expected.to eq(:development)
    end
  end

  context "RACK_ENV in ENV" do
    let(:env) { { "RACK_ENV" => "production" } }

    it "is the value of RACK_ENV" do
      is_expected.to eq(:production)
    end
  end

  context "no ENV vars set" do
    let(:env) { {} }

    it "defaults to \"development\"" do
      is_expected.to eq(:development)
    end
  end
end
