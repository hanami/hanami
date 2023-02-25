require "hanami"

RSpec.describe "App view / Context / Request", :app_integration do
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

  subject(:context) {
    context_class.new(request: request)
  }

  let(:request) { double(:request) }

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
      allow(request).to receive(:flash) { flash }
    end

    it "is the request's flash" do
      expect(context.flash).to be flash
    end
  end
end
