# frozen_string_literal: true

require "hanami/slice_name"

require "dry/inflector"

RSpec.describe Hanami::SliceName do
  subject(:slice_name) { described_class.new(slice, inflector: -> { inflector }) }
  let(:slice) { double(name: "Main::Slice") }
  let(:inflector) { Dry::Inflector.new }

  let(:slice_module) { Module.new }

  before do
    stub_const "Main", slice_module
  end

  describe "#name" do
    it "returns the downcased, underscored string name of the module containing the slice" do
      expect(slice_name.name).to eq "main"
    end
  end

  describe "#to_s" do
    it "returns the downcased, underscored string name of the module containing the slice" do
      expect(slice_name.to_s).to eq "main"
    end
  end

  describe "#to_sym" do
    it "returns the downcased, underscored, symbolized name of the module containing the slice" do
      expect(slice_name.to_sym).to eq :main
    end
  end

  describe "#namespace_name" do
    it "returns the string name of the module containing the slice" do
      expect(slice_name.namespace_name).to eq "Main"
    end
  end

  describe "#namespace_const" do
    it "returns the module containing the slice" do
      expect(slice_name.namespace).to be slice_module
    end
  end
end
