# frozen_string_literal: true

require "hanami"
require "hanami/view"
require "hanami/view/context"
require "hanami/extensions/view/context"

RSpec.describe Hanami::Extensions::View::Context do
  describe "leaving the base Hanami::View::Context class unmodified" do
    it "does not prepend the integrated instance methods onto the base class" do
      expect(Hanami::View::Context.include?(described_class::ClassExtension::InstanceMethods))
        .to be false
    end

    it "leaves Hanami::View::Context.new usable with no arguments" do
      expect { Hanami::View::Context.new }.not_to raise_error
    end

    context "after a Hanami app has booted and used a slice-configured context", :app_integration do
      before do
        module TestApp
          class App < Hanami::App
          end
        end

        Hanami.prepare

        module TestApp
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      end

      it "still does not prepend the integrated instance methods onto the base class" do
        expect(Hanami::View::Context.include?(described_class::ClassExtension::InstanceMethods))
          .to be false
      end

      it "still leaves Hanami::View::Context.new usable with no arguments" do
        expect { Hanami::View::Context.new }.not_to raise_error
      end
    end
  end

  describe "a slice-configured context class", :app_integration do
    before do
      module TestApp
        class App < Hanami::App
        end
      end

      Hanami.prepare

      module TestApp
        module Views
          class Context < Hanami::View::Context
          end
        end
      end
    end

    subject(:context) { TestApp::Views::Context.new(**args) }
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
end
