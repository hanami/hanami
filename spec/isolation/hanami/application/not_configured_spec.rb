# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application" do
    it "it raises error when not configured" do
      expect { Hanami.application_class }.to raise_error("Hanami application not configured")
    end
  end
end
