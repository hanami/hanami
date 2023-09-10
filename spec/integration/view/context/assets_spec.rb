# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Context / Assets", :app_integration do
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

  let(:context_class) { TestApp::Views::Context }
  subject(:context) { context_class.new }

  describe "#assets" do
    context "without assets provider" do
      xit "raises error" do
        allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(false)

        expect { context.assets }
          .to raise_error(Hanami::ComponentLoadError, /hanami-assets/)
      end
    end

    context "with assets provider" do
      it "is the app assets by default" do
        expect(context.assets).to be TestApp::App[:assets]
      end

      context "injected assets" do
        subject(:context) {
          context_class.new(assets: assets)
        }

        let(:assets) { double(:assets) }

        it "is the injected assets" do
          expect(context.assets).to be assets
        end

        context "rebuilt context" do
          subject(:new_context) { context.with }

          it "retains the injected assets" do
            expect(new_context.assets).to be assets
          end
        end
      end
    end
  end
end
