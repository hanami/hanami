# frozen_string_literal: true

module Bookshelf
  class Application < Hanami::Application
  end
end

RSpec.describe Hanami do
  describe ".application" do
    it "it raises error when already assigned" do
      expect do
        module Soundcard
          class Application < Hanami::Application
          end
        end
      end.to raise_error("Hanami application already configured")
    end
  end
end
