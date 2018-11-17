# frozen_string_literal: true

module Bookshelf
  class Application < Hanami::Application
  end
end

Hanami.application.routes do
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
    it "assigns Hanami.app" do
      expect(Hanami::Container).to receive(:finalize!)

      Hanami.boot
      expect(Hanami.app).to be_kind_of(Hanami::Application)
    end
  end
end
