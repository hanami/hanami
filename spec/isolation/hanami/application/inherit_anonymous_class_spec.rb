# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application" do
    it "it doesn't assign when anonymous class inherits Hanami::Application" do
      Class.new(Hanami::Application)
      expect { Hanami.application }.to raise_error("Hanami.application not configured")
    end
  end
end
