# frozen_string_literal: true

require "hanami/action"
require "hanami/logger"

module Bookshelf
  class Application < Hanami::Application
  end
end

module Web
end
slice = Hanami.application.register_slice :web, namespace: Web

Hanami.init

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

slice.register "actions.home.index" do
  Web::Actions::Home::Index.new
end

RSpec.describe Hanami do
  describe ".boot" do
    it "assigns Hanami.application, .root, and .logger" do
      pending "Failing due to dry-system changes"

      Hanami.boot
      expect(Hanami.application.ancestors).to include(Hanami::Application)
      expect(Hanami.application.root).to eq(Dir.pwd)
      expect(Hanami.logger).to be_kind_of(Hanami::Logger)
    end
  end
end
