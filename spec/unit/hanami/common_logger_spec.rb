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
        expect(device.read).to include(%(:path=>"logo.png"))
      end
    end

    context "when ELAPSED time is present" do
      it "returns the elapsed time" do
        freeze_clock_time_at(Time.at(0), Time.at(1)) do
          get "/"
        end

        device.rewind
        expect(device.read).to include(%(:elapsed=>"1.0000"))
      end
    end
  end

  # For the sake of simplicity this method receives only the parameters
  # it needs to provide data for the calculation of elapsed time, which
  # means basically, two times:
  #
  # begin_at..now
  def freeze_clock_time_at(first, second)
    times = [first, second].map(&:to_f)

    clazz = class << Process; self; end
    clazz.send :alias_method, :xyz, :clock_gettime
    clazz.send :define_method, :clock_gettime do |_|
      times.shift
    end

    yield
  ensure
    clazz.send :undef_method, :clock_gettime
    clazz.send :alias_method, :clock_gettime, :xyz
  end
end
