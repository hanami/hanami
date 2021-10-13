require "spec_helper"
require "ostruct"

RSpec.describe Hanami::Config::Sessions do
  describe "#initialize" do
    it "returns an instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end
  end

  describe "#enabled?" do
    it "is false by default" do
      expect(subject.enabled?).to be(false)
    end

    it "is true when adapter is present" do
      subject = described_class.new(:cookie)
      expect(subject.enabled?).to be(true)
    end
  end

  describe "#middleware" do
    it "returns Rack sessions middleware and options" do
      subject = described_class.new(:redis)

      rack_middleware_class, options = subject.middleware
      expect(rack_middleware_class).to eq("Rack::Session::Redis")
      expect(options).to match({})
    end

    it "returns custom options for the middleware" do
      subject = described_class.new(:redis, opts = { redis_server: "redis://redis:6379/0" })

      _, options = subject.middleware
      expect(options).to match(opts)
    end

    it "returns default serializer for Cookie storage" do
      subject = described_class.new(:cookie)

      rack_middleware_class, options = subject.middleware
      expect(rack_middleware_class).to eq("Rack::Session::Cookie")
      expect(options).to match(coder: an_instance_of(Rack::Session::Cookie::Base64::JSON))
    end

    it "allows to override default serializer for Cookie storage" do
      subject = described_class.new(:cookie, coder: coder = Object.new)

      _, options = subject.middleware
      expect(options).to match(coder: coder)
    end

    it "sets domain and secure settings from configuration" do
      configuration = OpenStruct.new(host: domain = "hanamirb.test", ssl?: ssl = true)
      subject = described_class.new(:redis, {}, configuration)

      _, options = subject.middleware
      expect(options).to match(domain: domain, secure: ssl)
    end
  end
end
