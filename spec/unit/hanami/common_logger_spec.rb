require "spec_helper"
require "rack/test"

RSpec.describe Hanami::CommonLogger do
  include Rack::Test::Methods

  describe "#call" do
    let(:app) do
      app = lambda do |env|
        env["rack.errors"] = device
        env["PATH_INFO"] = Pathname.new("logo.png")
        [200, {}, ["OK"]]
      end
      builder = Rack::Builder.new
      builder.use described_class
      builder.run app
      builder
    end
    let(:device) { StringIO.new }

    context "when PATH_INFO is a Pathname" do
      it "returns the string representation" do
        get "/"

        device.rewind
        read_device = device.read
        expect(read_device).to include(%(:path=>"logo.png"))
        expect(read_device).to include(%(:elapsed=>0.))
      end
    end
  end
end
