# frozen_string_literal: true

require "hanami/action"

module Bookshelf
  class Application < Hanami::Application
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

Hanami.application.routes do
  mount :web, at: "/" do
    root to: "home#index"
  end
end

RSpec.describe Hanami::Application do
  describe ".routes" do
    subject { Hanami.application.routes }

    it "returns configured routes" do
      expect(subject).to be_kind_of(Proc)
      # FIXME: make this expectation to pass
      # expect(subject.for(:web).url(:root)).to eq("/")
    end
  end
end
