# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application" do
    it "it doesn't assign when anonymous class inherits Hanami::Application" do
      Class.new(Hanami::Application)
      expect { Hanami.app }.to raise_error("Hanami.app not configured")
    end
  end
end
