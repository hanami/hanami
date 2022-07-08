# frozen_string_literal: true

require "hanami/action"

module Bookshelf
  class App < Hanami::App
  end
end

module Web
end
Hanami.app.register_slice :web, namespace: Web

Hanami.prepare

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

Hanami.app.routes do
  mount :web, at: "/" do
    root to: "home#index"
  end
end

RSpec.describe Hanami::Application do
  describe ".routes" do
    subject { Hanami.app.routes }

    it "returns configured routes" do
      expect(subject).to be_kind_of(Proc)
      # FIXME: make this expectation to pass
      # expect(subject.for(:web).url(:root)).to eq("/")
    end
  end
end
