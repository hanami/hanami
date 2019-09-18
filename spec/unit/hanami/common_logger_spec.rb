require "spec_helper"
require "rack/test"

RSpec.describe Hanami::CommonLogger do
  include Rack::Test::Methods

  describe "#call" do
    let(:app) do
      exception = StandardError.new("Exception")
      exception.set_backtrace(['backtrace/path/1', 'backtrace/path/2'])
      app = lambda do |env|
        env["rack.errors"] = device
        env["rack.exception"] = exception
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
        expect(device.read).to include(%(:path=>"logo.png"))
      end
    end

    context "when rack.exception is present" do
      it "populates exception info" do
        get "/"

        device.rewind
        exception_info = %(:message=>"Exception", :backtrace=>["backtrace/path/1", "backtrace/path/2"], :error=>StandardError)
        expect(device.read).to include(exception_info)
      end
    end
  end
end
