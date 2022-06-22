# frozen_string_literal: true

require "hanami"

RSpec.describe "Application view / Context / Assets", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        register_slice :main
      end
    end

    Hanami.prepare

    module TestApp
      module Views
        class Context < Hanami::View::Context
        end
      end
    end

    module Main
      module Views
        class Context < TestApp::Views::Context
        end
      end
    end
  end

  let(:context_class) { Main::Views::Context }
  subject(:context) { context_class.new }

  describe "#assets" do
    context "without assets provider" do
      it "raises error" do
        expect { context.assets }
          .to raise_error(Hanami::ComponentLoadError, /hanami-assets/)
      end
    end

    context "with assets provider" do
      before do
        Hanami.application.register_provider(:assets) do
          start do
            register "assets", Object.new
          end
        end
      end

      it "is the application assets by default" do
        expect(context.assets).to be TestApp::Application[:assets]
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
