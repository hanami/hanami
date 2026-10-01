# frozen_string_literal: true

RSpec.describe Hanami, ".bundled?" do
  let(:gem_name) { "some-gem" }

  after { Hanami.instance_variable_get(:@_bundled).delete(gem_name) }

  context "gem is not yet activated" do
    before { allow(Hanami).to receive(:gem).with(gem_name).and_return(true) }

    it "returns true" do
      expect(Hanami.bundled?(gem_name)).to be true
    end
  end

  context "gem is already activated" do
    # Outside of Bundler, Kernel#gem returns false for already activated gems
    before { allow(Hanami).to receive(:gem).with(gem_name).and_return(false) }

    it "returns true" do
      expect(Hanami.bundled?(gem_name)).to be true
    end
  end

  context "gem cannot be loaded" do
    before { allow(Hanami).to receive(:gem).with(gem_name).and_raise(Gem::LoadError) }

    it "returns false" do
      expect(Hanami.bundled?(gem_name)).to be false
    end

    it "memoizes the result" do
      2.times { Hanami.bundled?(gem_name) }

      expect(Hanami).to have_received(:gem).once
    end
  end
end
