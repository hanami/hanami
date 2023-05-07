require "hanami/view"
require "hanami/view/context"
require "hanami/extensions/view/context"

RSpec.describe(Hanami::View::Context) do
  subject(:context) { described_class.new(**args) }
  let(:args) { {} }

  describe "#assets" do
    context "assets given" do
      let(:args) { {assets: assets} }
      let(:assets) { double(:assets) }

      it "returns the assets" do
        expect(context.assets).to be assets
      end
    end

    context "no assets given" do
      it "raises a Hanami::ComponentLoadError" do
        expect { context.assets }.to raise_error Hanami::ComponentLoadError
      end
    end
  end

  describe "#request" do
    context "request given" do
      let(:args) { {request: request} }
      let(:request) { double(:request) }

      it "returns the request" do
        expect(context.request).to be request
      end
    end

    context "no request given" do
      it "raises a Hanami::ComponentLoadError" do
        expect { context.request }.to raise_error Hanami::ComponentLoadError
      end
    end
  end

  describe "#routes" do
    context "routes given" do
      let(:args) { {routes: routes} }
      let(:routes) { double(:routes) }

      it "returns the routes" do
        expect(context.routes).to be routes
      end
    end

    context "no routes given" do
      it "raises a Hanami::ComponentLoadError" do
        expect { context.routes }.to raise_error Hanami::ComponentLoadError
      end
    end
  end
end
