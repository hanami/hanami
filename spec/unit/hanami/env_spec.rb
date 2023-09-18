# frozen_string_literal: true

RSpec.describe Hanami, ".env" do
  subject { described_class.env(e: env) }

  context "HANAMI_ENV in ENV" do
    let(:env) { {"HANAMI_ENV" => "test"} }

    it "is the value of HANAMI_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "RACK_ENV in ENV" do
    let(:env) { {"HANAMI_ENV" => "test"} }

    it "is the value of RACK_ENV" do
      is_expected.to eq(:test)
    end
  end

  context "both HANAMI_ENV and RACK_ENV in ENV" do
    let(:env) do
      {"HANAMI_ENV" => "test",
       "RACK_ENV" => "production"}
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
end
