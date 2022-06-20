# frozen_string_literal: true

require "hanami/routes"

RSpec.describe Hanami::Routes do
  describe ".define" do
    it "sets routes block" do
      routes_class = Class.new(described_class)

      routes_class.define { "Dummy routes" }

      expect(routes_class.routes.call).to eq("Dummy routes")
    end
  end

  describe ".routes" do
    context "when called before the routes have been defined" do
      it "raises an error" do
        routes_class = Class.new(described_class)

        expect { routes_class.routes }.to raise_error(RuntimeError)
      end
    end
  end
end
