# frozen_string_literal: true

module Bookshelf
  class App < Hanami::App
  end
end

RSpec.describe Hanami do
  describe ".application" do
    it "it assign when concrete class inherits Hanami::Application" do
      expect(Hanami.app).to eq(Bookshelf::Application)
    end
  end
end
