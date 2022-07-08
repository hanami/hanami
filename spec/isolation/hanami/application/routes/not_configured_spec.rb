# frozen_string_literal: true

module Bookshelf
  class App < Hanami::App
  end
end

RSpec.describe Hanami::Application do
  describe ".routes" do
    subject { Hanami.app.routes }

    it "raises error when not configured" do
      expect { subject }.to raise_error("Hanami.app.routes not configured")
    end
  end
end
