# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application_class" do
    it "it raises error when not configured" do
      expect { Hanami.application_class }.to raise_error("Hanami.application_class not configured")
    end
  end
end
