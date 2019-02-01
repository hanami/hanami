# frozen_string_literal: true

RSpec.describe Hanami do
  describe ".application" do
    it "it doesn't assign when anonymous class inherits Hanami::Application" do
      Class.new(Hanami::Application)
      expect { Hanami.application_class }.to raise_error("Hanami.application_class not configured")
    end
  end
end
