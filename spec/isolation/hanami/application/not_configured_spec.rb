# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application" do
    it "it raises error when not configured" do
      expect { Hanami.app }.to raise_error("Hanami.app not configured")
    end
  end
end
