# frozen_string_literal: true

RSpec.describe Hanami, ".env" do
  subject { described_class.env(e: env) }

  context "HANAMI_ENV in ENV" do
    let(:env) { {"HANAMI_ENV" => "test"} }

    it "is the value of HANAMI_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "APP_ENV in ENV" do
    let(:env) { {"HANAMI_ENV" => "test"} }

    it "is the value of APP_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "both HANAMI_ENV and APP_ENV in ENV" do
    let(:env) do
      {"HANAMI_ENV" => "test",
       "APP_ENV" => "production"}
    end

    it "is the value of HANAMI_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "no ENV vars set" do
    let(:env) { {} }

    it "defaults to \"development\"" do
      is_expected.to eq(:development)
    end
  end

  # TODO: [#1487] remove RACK_ENV (1 context)
  context "both HANAMI_ENV and deprecated RACK_ENV set" do
    let (:env) do
      {"HANAMI_ENV" => "test",
       "RACK_ENV" => "production"}
    end

    it "is the value of HANAMI_ENV" do
      is_expected.to eq(:test)
    end
  end

  # TODO: [#1487] remove RACK_ENV (1 context)
  context "both APP_ENV and deprecated RACK_ENV set" do
    let (:env) do
      {"APP_ENV" => "test",
       "RACK_ENV" => "production"}
    end

    it "is the value of APP_ENV" do
      is_expected.to eq(:production)
    end
  end
end
