# frozen_string_literal: true

module Bookshelf
  class Application < Hanami::Application
  end
end

Hanami.application.routes do
end

RSpec.describe Hanami do
  describe ".boot" do
    it "raises error if already booted" do
      expect(Hanami::Container).to receive(:finalize!).and_return(nil)

      Hanami.boot
      expect { Hanami.boot }.to raise_error("Hanami application already booted")
    end
  end
end
