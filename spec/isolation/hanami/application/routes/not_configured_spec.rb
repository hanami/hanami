# frozen_string_literal: true

module Bookshelf
  class Application < Hanami::Application
  end
end

RSpec.describe Hanami::Application do
  describe ".routes" do
    subject { Hanami.application.routes }

    it "raises error when not configured" do
      expect { subject }.to raise_error("Hanami.application.routes not configured")
    end
  end
end
