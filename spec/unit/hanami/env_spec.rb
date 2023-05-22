RSpec.describe Hanami, ".env" do
  subject(:env) { described_class.env }

  before do
    @orig_env = ENV.to_h
  end

  after do
    ENV.replace(@orig_env)
  end

  context "HANAMI_ENV in ENV" do
    before do
      ENV["HANAMI_ENV"] = "test"
    end

    it "is the value of HANAMI_ENV" do
      is_expected.to eq :test
    end
  end

  context "RACK_ENV in ENV" do
    before do
      ENV["RACK_ENV"] = "test"
    end

    it "is the value of RACK_ENV" do
      is_expected.to eq :test
    end
  end

  context "both HANAMI_ENV and RACK_ENV in ENV" do
    before do
      ENV["HANAMI_ENV"] = "test"
      ENV["RACK_ENV"] = "production"
    end

    it "is the value of HANAMI_ENV" do
      is_expected.to eq :test
    end
  end

  context "no ENV vars set" do
    before do
      ENV.delete("HANAMI_ENV")
    end

    it "defaults to \"development\"" do
      is_expected.to eq :development
    end
  end
end
