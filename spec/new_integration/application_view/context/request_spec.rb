require "hanami"
require "hanami/application/view/context"

RSpec.describe "Application view / Context / Request", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        register_slice :main
      end
    end

    Hanami.prepare

    module TestApp
      module View
        class Context < Hanami::Application::View::Context
        end
      end
    end

    module Main
      module View
        class Context < TestApp::View::Context
        end
      end
    end
  end

  let(:context_class) { Main::View::Context }

  subject(:context) {
    context_class.new(
      request: request,
      response: response,
    )
  }

  let(:request) { double(:request) }
  let(:response) { double(:response) }

  describe "#request" do
    it "is the provided request" do
      expect(context.request).to be request
    end
  end

  describe "#sesion" do
    let(:session) { double(:session) }

    before do
      allow(request).to receive(:session) { session }
    end

    it "is the request's session" do
      expect(context.session).to be session
    end
  end

  describe "#flash" do
    let(:flash) { double(:flash) }

    before do
      allow(response).to receive(:flash) { flash }
    end

    it "is the response's flash" do
      expect(context.flash).to be flash
    end
  end
end
