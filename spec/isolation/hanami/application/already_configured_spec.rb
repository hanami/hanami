# frozen_string_literal: true

module Bookshelf
  class App < Hanami::App
  end
end

RSpec.describe Hanami do
  describe ".application" do
    it "it raises error when already assigned" do
      expect do
        module Soundcard
          class App < Hanami::App
          end
        end
      end.to raise_error("Hanami.app already configured")
    end
  end
end
