RSpec.describe Hanami::Configuration do
  describe "#initialize" do
    it "isn't frozen when initialized" do
      subject = described_class.new{}
      expect(subject.frozen?).to be(false)
    end
  end
end
