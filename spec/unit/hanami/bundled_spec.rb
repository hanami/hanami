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

  context "first-party gem" do
    let(:gem_name) { "hanami-router" }
    let(:requirements) { Hanami::GemVersionCheck.requirements_for(gem_name) }

    before do
      # Loading hanami already checks for hanami-router, so clear its memoized result
      Hanami.instance_variable_get(:@_bundled).delete(gem_name)
      allow(Hanami).to receive(:gem).with(gem_name, *requirements).and_return(true)
    end

    it "activates a version on the same major.minor as hanami" do
      expect(Hanami.bundled?(gem_name)).to be true
      expect(Hanami).to have_received(:gem).with(gem_name, *requirements)
    end
  end
end
