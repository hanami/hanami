# frozen_string_literal: true

module Bookshelf
  class Application < Hanami::Application
  end
end

RSpec.describe Hanami do
  describe ".boot" do
    it "assigns Hanami.app" do
      Hanami.boot
      expect(Hanami.app).to be_kind_of(Hanami::Application)
    end
  end
end
