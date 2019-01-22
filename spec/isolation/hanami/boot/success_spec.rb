# frozen_string_literal: true

require "hanami/logger"

module Bookshelf
  class Application < Hanami::Application
  end
end

Hanami.application_class.routes do
  mount :web, at: "/" do
    root to: "home#index"
  end
end

module Web
  class Action < Hanami::Action
  end

  module Actions
    module Home
      class Index < Web::Action
      end
    end
  end
end

RSpec.describe Hanami do
  describe ".boot" do
    it "assigns Hanami.application, .root, and .logger" do
      expect(Hanami::Container).to receive(:finalize!)
      expect(Hanami::Container).to receive(:[]).with("apps.web.actions.namespace").and_return(Web::Actions)
      expect(Hanami::Container).to receive(:[]).with("apps.web.actions.configuration").and_return(Hanami::Controller::Configuration.new)
      expect(Hanami::Container).to receive(:[]).with(:logger).and_return(Hanami::Logger.new)

      Hanami.boot
      expect(Hanami.app).to be_kind_of(Hanami::Application)
      expect(Hanami.application).to be_kind_of(Hanami::Application)
      expect(Hanami.root).to eq(Pathname.new(Dir.pwd))
      expect(Hanami.logger).to be_kind_of(Hanami::Logger)
    end
  end
end
